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
      _effect(chaining::value::holder<ui::effect_ptr>::make_shared(nullptr)),
      _effect_setter(chaining::notifier<ui::effect_ptr>::make_shared()),
      _scale_factor(chaining::value::holder<double>::make_shared(1.0)),
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

    this->_effect->set_value(ui::effect::make_through_effect());
    this->_effect_observer =
        this->_effect_setter->chain()
            .to([](ui::effect_ptr const &effect) { return effect ?: ui::effect::make_through_effect(); })
            .send_to(this->_effect)
            .end();

    this->_set_textures_to_effect();
}

ui::layout_guide_rect_ptr &ui::render_target::layout_guide_rect() {
    return this->_layout_guide_rect;
}

void ui::render_target::set_scale_factor(double const scale_factor) {
    this->_scale_factor->set_value(scale_factor);
}

double ui::render_target::scale_factor() const {
    return this->_scale_factor->value();
}

void ui::render_target::set_effect(ui::effect_ptr effect) {
    this->_effect_setter->notify(effect);
}

ui::effect_ptr const &ui::render_target::effect() {
    return this->_effect->value();
}

std::shared_ptr<chaining::receiver<double>> ui::render_target::scale_factor_receiver() {
    return this->_scale_factor;
}

void ui::render_target::sync_scale_from_renderer(ui::renderer_ptr const &renderer) {
    this->_scale_observer = renderer->chain_scale_factor().send_to(this->scale_factor_receiver()).sync();
}

void ui::render_target::_prepare(ui::render_target_ptr const &target) {
    this->_weak_render_target = target;

    auto weak_target = to_weak(target);

    this->_src_texture_observer =
        this->_src_texture->chain(ui::texture::method::metal_texture_changed)
            .perform([weak_target](ui::texture_ptr const &texture) {
                if (ui::render_target_ptr const target = weak_target.lock()) {
                    auto renderPassDescriptor = *target->_render_pass_descriptor;

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
            .end();

    this->_dst_texture_observer =
        this->_dst_texture->chain(ui::texture::method::size_updated)
            .perform([weak_target](ui::texture_ptr const &texture) {
                if (ui::render_target_ptr target = weak_target.lock()) {
                    target->_data->set_rect_tex_coords(
                        ui::uint_region{.origin = ui::uint_point::zero(), .size = texture->actual_size()}, 0);
                }
            })
            .end();

    this->_update_observers.emplace_back(this->_effect->chain()
                                             .perform([weak_target](ui::effect_ptr const &) {
                                                 if (auto target = weak_target.lock()) {
                                                     target->_set_updated(render_target_update_reason::effect);
                                                     target->_set_textures_to_effect();
                                                 }
                                             })
                                             .end());

    this->_update_observers.emplace_back(this->_scale_factor->chain()
                                             .perform([weak_target](double const &scale_factor) {
                                                 if (auto target = weak_target.lock()) {
                                                     target->_src_texture->set_scale_factor(scale_factor);
                                                     target->_dst_texture->set_scale_factor(scale_factor);
                                                     target->_set_updated(render_target_update_reason::scale_factor);
                                                 }
                                             })
                                             .end());

    this->_rect_observer = this->_layout_guide_rect->chain()
                               .guard([weak_target](ui::region const &) { return !weak_target.expired(); })
                               .perform([weak_target](ui::region const &region) {
                                   auto const target = weak_target.lock();

                                   ui::uint_size size{.width = static_cast<uint32_t>(region.size.width),
                                                      .height = static_cast<uint32_t>(region.size.height)};

                                   target->_src_texture->set_point_size(size);
                                   target->_dst_texture->set_point_size(size);

                                   target->_projection_matrix = ui::matrix::ortho(
                                       region.left(), region.right(), region.bottom(), region.top(), -1.0f, 1.0f);

                                   target->_data->set_rect_position(region, 0);

                                   target->_set_updated(render_target_update_reason::region);
                               })
                               .end();
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

ui::mesh_ptr const &ui::render_target::mesh() {
    return _mesh;
}

ui::render_target_updates_t &ui::render_target::updates() {
    return this->_updates;
}

void ui::render_target::clear_updates() {
    this->_updates.flags.reset();
    renderable_mesh::cast(this->_mesh)->clear_updates();
    if (auto &effect = this->_effect->value()) {
        renderable_effect::cast(effect)->clear_updates();
    }
}

MTLRenderPassDescriptor *ui::render_target::renderPassDescriptor() {
    return *this->_render_pass_descriptor;
}

simd::float4x4 &ui::render_target::projection_matrix() {
    return this->_projection_matrix;
}

bool ui::render_target::push_encode_info(ui::render_stackable_ptr const &stackable) {
    if (!this->_is_size_enough()) {
        return false;
    }

    auto target = this->_weak_render_target.lock();
    if (auto const &metal_system = this->_metal_system) {
        ui::renderable_metal_system::cast(metal_system)->push_render_target(stackable, target);
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
    if (auto const &effect = this->_effect->value()) {
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
    auto shared = std::shared_ptr<render_target>(new render_target{});
    shared->_prepare(shared);
    return shared;
}
