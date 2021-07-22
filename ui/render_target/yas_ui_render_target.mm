//
//  yas_ui_render_target.mm
//

#include "yas_ui_render_target.h"
#include <cpp_utils/yas_unless.h>
#include <ui/yas_ui_effect.h>
#include <ui/yas_ui_layout_guide.h>
#include <ui/yas_ui_matrix.h>
#include <ui/yas_ui_mesh.h>
#include <ui/yas_ui_metal_texture.h>
#include <ui/yas_ui_rect_plane.h>
#include <ui/yas_ui_renderer.h>
#include <ui/yas_ui_texture.h>
#include <ui/yas_ui_view_look.h>

using namespace yas;
using namespace yas::ui;

render_target::render_target(std::shared_ptr<ui::view_look_scale_factor_interface> const &view_look)
    : _layout_guide(layout_region_guide::make_shared()),
      _effect(effect::make_through_effect()),
      _scale_factor(1.0),
      _data(rect_plane_data::make_shared(1)),
      _src_texture(texture::make_shared({.point_size = uint_size::zero(),
                                         .scale_factor = 0.0,
                                         .draw_padding = 0,
                                         .usages = {texture_usage::render_target, texture_usage::shader_read},
                                         .pixel_format = pixel_format::bgra8_unorm},
                                        view_look)),
      _dst_texture(texture::make_shared({.point_size = uint_size::zero(),
                                         .scale_factor = 0.0,
                                         .draw_padding = 0,
                                         .usages = {texture_usage::shader_write},
                                         .pixel_format = pixel_format::bgra8_unorm},
                                        view_look)) {
    this->_updates.flags.set();
    this->_render_pass_descriptor = objc_ptr_with_move_object([MTLRenderPassDescriptor new]);
    this->_mesh->set_mesh_data(this->_data->dynamic_mesh_data());
    this->_mesh->set_texture(this->_dst_texture);

    this->_set_textures_to_effect();

    this->_src_texture
        ->observe_metal_texture_changed([this](auto const &) {
            std::shared_ptr<texture> const &texture = this->_src_texture;
            auto const renderPassDescriptor = *this->_render_pass_descriptor;

            if (std::shared_ptr<metal_texture> const &metal_texture = texture->metal_texture()) {
                auto color_desc = objc_ptr_with_move_object([MTLRenderPassColorAttachmentDescriptor new]);
                auto colorDesc = *color_desc;
                colorDesc.texture = metal_texture->texture();
                colorDesc.loadAction = MTLLoadActionClear;
                colorDesc.clearColor = MTLClearColorMake(0.0, 0.0, 0.0, 0.0);

                [renderPassDescriptor.colorAttachments setObject:colorDesc atIndexedSubscript:0];
            } else {
                [renderPassDescriptor.colorAttachments setObject:nil atIndexedSubscript:0];
            }
        })
        .end()
        ->add_to(this->_pool);

    this->_dst_texture
        ->observe_size_updated([this](auto const &) {
            std::shared_ptr<texture> const &texture = this->_dst_texture;
            this->_data->set_rect_tex_coords(uint_region{.origin = uint_point::zero(), .size = texture->actual_size()},
                                             0);
        })
        .end()
        ->add_to(this->_pool);

    this->_layout_guide
        ->observe([this](region const &region) {
            uint_size size{.width = static_cast<uint32_t>(region.size.width),
                           .height = static_cast<uint32_t>(region.size.height)};

            this->_src_texture->set_point_size(size);
            this->_dst_texture->set_point_size(size);

            this->_projection_matrix =
                matrix::ortho(region.left(), region.right(), region.bottom(), region.top(), -1.0f, 1.0f);

            this->_data->set_rect_position(region, 0);

            this->_set_updated(render_target_update_reason::region);
        })
        .end()
        ->add_to(this->_pool);

    view_look->observe_scale_factor([this](double const &scale) { this->set_scale_factor(scale); })
        .sync()
        ->add_to(this->_pool);
}

std::shared_ptr<layout_region_guide> &render_target::layout_guide() {
    return this->_layout_guide;
}

void render_target::set_scale_factor(double const scale_factor) {
    if (this->_scale_factor != scale_factor) {
        this->_scale_factor = scale_factor;

        this->_src_texture->set_scale_factor(scale_factor);
        this->_dst_texture->set_scale_factor(scale_factor);
        this->_set_updated(render_target_update_reason::scale_factor);
    }
}

double render_target::scale_factor() const {
    return this->_scale_factor;
}

void render_target::set_effect(std::shared_ptr<ui::effect> effect) {
    if (this->_effect != effect) {
        this->_effect = effect ?: effect::make_through_effect();

        this->_set_updated(render_target_update_reason::effect);
        this->_set_textures_to_effect();
    }
}

std::shared_ptr<effect> const &render_target::effect() const {
    return this->_effect;
}

setup_metal_result render_target::metal_setup(std::shared_ptr<metal_system> const &metal_system) {
    if (this->_metal_system != metal_system) {
        this->_metal_system = metal_system;
    }

    if (auto ul = unless(metal_object::cast(this->_src_texture)->metal_setup(metal_system))) {
        return ul.value;
    }

    if (auto ul = unless(metal_object::cast(this->_dst_texture)->metal_setup(metal_system))) {
        return ul.value;
    }

    return setup_metal_result{nullptr};
}

std::shared_ptr<mesh> const &render_target::mesh() const {
    return _mesh;
}

render_target_updates_t const &render_target::updates() const {
    return this->_updates;
}

void render_target::clear_updates() {
    this->_updates.flags.reset();
    renderable_mesh::cast(this->_mesh)->clear_updates();
    if (auto &effect = this->_effect) {
        renderable_effect::cast(effect)->clear_updates();
    }
}

MTLRenderPassDescriptor *render_target::renderPassDescriptor() const {
    return *this->_render_pass_descriptor;
}

simd::float4x4 const &render_target::projection_matrix() const {
    return this->_projection_matrix;
}

bool render_target::push_encode_info(std::shared_ptr<render_stackable> const &stackable) {
    if (!this->_is_size_enough()) {
        return false;
    }

    if (auto const &metal_system = this->_metal_system) {
        renderable_metal_system::cast(metal_system)->push_render_target(stackable, this);
        return true;
    }
    return false;
}

void render_target::_set_updated(render_target_update_reason const reason) {
    this->_updates.set(reason);
}

bool render_target::_is_size_updated() {
    static render_target_updates_t const _size_updates = {render_target_update_reason::scale_factor,
                                                          render_target_update_reason::region};
    return this->_updates.and_test(_size_updates);
}

void render_target::_set_textures_to_effect() {
    if (auto const &effect = this->_effect) {
        renderable_effect::cast(effect)->set_textures(this->_src_texture, this->_dst_texture);
    }
}

bool render_target::_is_size_enough() {
    if (auto const &texture = this->_dst_texture) {
        uint_size const actual_size = texture->actual_size();
        if (actual_size.width > 0 && actual_size.height > 0) {
            return true;
        }
    }
    return false;
}

std::shared_ptr<render_target> render_target::make_shared(
    std::shared_ptr<ui::view_look_scale_factor_interface> const &view_look) {
    return std::shared_ptr<render_target>(new render_target{view_look});
}
