//
//  yas_ui_render_target.mm
//

#include "yas_ui_render_target.h"
#include <cpp_utils/yas_unless.h>
#include "yas_ui_effect.h"
#include "yas_ui_layout_guide.h"
#include "yas_ui_matrix.h"
#include "yas_ui_mesh.h"
#include "yas_ui_metal_texture.h"
#include "yas_ui_rect_plane.h"
#include "yas_ui_renderer.h"
#include "yas_ui_texture.h"

using namespace yas;

ui::render_target::render_target()
    : _layout_guide_rect(ui::layout_guide_rect::make_shared()),
      _effect(ui::effect::make_through_effect()),
      _scale_factor(1.0),
      _data(ui::rect_plane_data::make_shared(1)),
      _src_texture(
          ui::texture::make_shared({.point_size = ui::uint_size::zero(),
                                    .scale_factor = 0.0,
                                    .draw_padding = 0,
                                    .usages = {ui::texture_usage::render_target, ui::texture_usage::shader_read},
                                    .pixel_format = ui::pixel_format::bgra8_unorm})),
      _dst_texture(ui::texture::make_shared({.point_size = ui::uint_size::zero(),
                                             .scale_factor = 0.0,
                                             .draw_padding = 0,
                                             .usages = {ui::texture_usage::shader_write},
                                             .pixel_format = ui::pixel_format::bgra8_unorm})) {
    this->_updates.flags.set();
    this->_render_pass_descriptor = objc_ptr_with_move_object([MTLRenderPassDescriptor new]);
    this->_mesh->set_mesh_data(this->_data->dynamic_mesh_data());
    this->_mesh->set_texture(this->_dst_texture);

    this->_set_textures_to_effect();

    this->_src_texture
        ->observe([this](auto const &pair) {
            if (pair.first == ui::texture::method::metal_texture_changed) {
                ui::texture const *texture = pair.second;
                auto const renderPassDescriptor = *this->_render_pass_descriptor;

                if (ui::metal_texture_ptr const &metal_texture = texture->metal_texture()) {
                    auto color_desc = objc_ptr_with_move_object([MTLRenderPassColorAttachmentDescriptor new]);
                    auto colorDesc = *color_desc;
                    colorDesc.texture = metal_texture->texture();
                    colorDesc.loadAction = MTLLoadActionClear;
                    colorDesc.clearColor = MTLClearColorMake(0.0, 0.0, 0.0, 0.0);

                    [renderPassDescriptor.colorAttachments setObject:colorDesc atIndexedSubscript:0];
                } else {
                    [renderPassDescriptor.colorAttachments setObject:nil atIndexedSubscript:0];
                }
            }
        })
        ->add_to(this->_pool);

    this->_dst_texture
        ->observe([this](auto const &pair) {
            if (pair.first == ui::texture::method::size_updated) {
                ui::texture const *texture = pair.second;
                this->_data->set_rect_tex_coords(
                    ui::uint_region{.origin = ui::uint_point::zero(), .size = texture->actual_size()}, 0);
            }
        })
        ->add_to(this->_pool);

    this->_layout_guide_rect
        ->observe(
            [this](ui::region const &region) {
                ui::uint_size size{.width = static_cast<uint32_t>(region.size.width),
                                   .height = static_cast<uint32_t>(region.size.height)};

                this->_src_texture->set_point_size(size);
                this->_dst_texture->set_point_size(size);

                this->_projection_matrix =
                    ui::matrix::ortho(region.left(), region.right(), region.bottom(), region.top(), -1.0f, 1.0f);

                this->_data->set_rect_position(region, 0);

                this->_set_updated(render_target_update_reason::region);
            },
            false)
        ->add_to(this->_pool);
}

ui::layout_guide_rect_ptr &ui::render_target::layout_guide_rect() {
    return this->_layout_guide_rect;
}

void ui::render_target::set_scale_factor(double const scale_factor) {
    if (this->_scale_factor != scale_factor) {
        this->_scale_factor = scale_factor;

        this->_src_texture->set_scale_factor(scale_factor);
        this->_dst_texture->set_scale_factor(scale_factor);
        this->_set_updated(render_target_update_reason::scale_factor);
    }
}

double ui::render_target::scale_factor() const {
    return this->_scale_factor;
}

void ui::render_target::set_effect(ui::effect_ptr effect) {
    if (this->_effect != effect) {
        this->_effect = effect ?: ui::effect::make_through_effect();

        this->_set_updated(render_target_update_reason::effect);
        this->_set_textures_to_effect();
    }
}

ui::effect_ptr const &ui::render_target::effect() const {
    return this->_effect;
}

void ui::render_target::sync_scale_from_renderer(ui::renderer_ptr const &renderer) {
    this->_scale_canceller =
        renderer->observe_scale_factor([this](double const &scale) { this->set_scale_factor(scale); }, true);
}

ui::setup_metal_result ui::render_target::metal_setup(std::shared_ptr<ui::metal_system> const &metal_system) {
    if (this->_metal_system != metal_system) {
        this->_metal_system = metal_system;
    }

    if (auto ul = unless(ui::metal_object::cast(this->_src_texture)->metal_setup(metal_system))) {
        return ul.value;
    }

    if (auto ul = unless(ui::metal_object::cast(this->_dst_texture)->metal_setup(metal_system))) {
        return ul.value;
    }

    return ui::setup_metal_result{nullptr};
}

ui::mesh_ptr const &ui::render_target::mesh() const {
    return _mesh;
}

ui::render_target_updates_t const &ui::render_target::updates() const {
    return this->_updates;
}

void ui::render_target::clear_updates() {
    this->_updates.flags.reset();
    renderable_mesh::cast(this->_mesh)->clear_updates();
    if (auto &effect = this->_effect) {
        renderable_effect::cast(effect)->clear_updates();
    }
}

MTLRenderPassDescriptor *ui::render_target::renderPassDescriptor() const {
    return *this->_render_pass_descriptor;
}

simd::float4x4 const &ui::render_target::projection_matrix() const {
    return this->_projection_matrix;
}

bool ui::render_target::push_encode_info(ui::render_stackable_ptr const &stackable) {
    if (!this->_is_size_enough()) {
        return false;
    }

    if (auto const &metal_system = this->_metal_system) {
        ui::renderable_metal_system::cast(metal_system)->push_render_target(stackable, this);
        return true;
    }
    return false;
}

void ui::render_target::_set_updated(ui::render_target_update_reason const reason) {
    this->_updates.set(reason);
}

bool ui::render_target::_is_size_updated() {
    static render_target_updates_t const _size_updates = {ui::render_target_update_reason::scale_factor,
                                                          ui::render_target_update_reason::region};
    return this->_updates.and_test(_size_updates);
}

void ui::render_target::_set_textures_to_effect() {
    if (auto const &effect = this->_effect) {
        renderable_effect::cast(effect)->set_textures(this->_src_texture, this->_dst_texture);
    }
}

bool ui::render_target::_is_size_enough() {
    if (auto const &texture = this->_dst_texture) {
        ui::uint_size const actual_size = texture->actual_size();
        if (actual_size.width > 0 && actual_size.height > 0) {
            return true;
        }
    }
    return false;
}

ui::render_target_ptr ui::render_target::make_shared() {
    return std::shared_ptr<render_target>(new render_target{});
}
