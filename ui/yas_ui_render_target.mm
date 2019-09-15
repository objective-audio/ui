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

#pragma mark - render_target::impl

struct ui::render_target::impl {
    impl()
        : _src_texture(
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

    void prepare(ui::render_target_ptr const &target) {
        this->_weak_render_target = target;

        auto weak_target = to_weak(target);

        this->_src_texture_observer =
            this->_src_texture->chain(ui::texture::method::metal_texture_changed)
                .perform([weak_target](ui::texture_ptr const &texture) {
                    if (ui::render_target_ptr const target = weak_target.lock()) {
                        auto renderPassDescriptor = *target->_impl->_render_pass_descriptor;

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
                        target->_impl->_data->set_rect_tex_coords(
                            ui::uint_region{.origin = ui::uint_point::zero(), .size = texture->actual_size()}, 0);
                    }
                })
                .end();

        this->_update_observers.emplace_back(this->_effect->chain()
                                                 .perform([weak_target](ui::effect_ptr const &) {
                                                     if (auto target = weak_target.lock()) {
                                                         target->_impl->_set_updated(
                                                             render_target_update_reason::effect);
                                                         target->_impl->_set_textures_to_effect();
                                                     }
                                                 })
                                                 .end());

        this->_update_observers.emplace_back(this->_scale_factor->chain()
                                                 .perform([weak_target](double const &scale_factor) {
                                                     if (auto target = weak_target.lock()) {
                                                         auto &imp = target->_impl;
                                                         imp->_src_texture->set_scale_factor(scale_factor);
                                                         imp->_dst_texture->set_scale_factor(scale_factor);
                                                         imp->_set_updated(render_target_update_reason::scale_factor);
                                                     }
                                                 })
                                                 .end());

        this->_rect_observer = this->_layout_guide_rect->chain()
                                   .guard([weak_target](ui::region const &) { return !weak_target.expired(); })
                                   .perform([weak_target](ui::region const &region) {
                                       auto &imp = weak_target.lock()->_impl;

                                       ui::uint_size size{.width = static_cast<uint32_t>(region.size.width),
                                                          .height = static_cast<uint32_t>(region.size.height)};

                                       imp->_src_texture->set_point_size(size);
                                       imp->_dst_texture->set_point_size(size);

                                       imp->_projection_matrix = ui::matrix::ortho(
                                           region.left(), region.right(), region.bottom(), region.top(), -1.0f, 1.0f);

                                       imp->_data->set_rect_position(region, 0);

                                       imp->_set_updated(render_target_update_reason::region);
                                   })
                                   .end();
    }

    ui::setup_metal_result metal_setup(ui::metal_system_ptr const &metal_system) {
        if (this->_metal_system != metal_system) {
            this->_metal_system = metal_system;
        }

        if (auto ul = unless(this->_src_texture->metal()->metal_setup(metal_system))) {
            return ul.value;
        }

        if (auto ul = unless(this->_dst_texture->metal()->metal_setup(metal_system))) {
            return ul.value;
        }

        return ui::setup_metal_result{nullptr};
    }

    ui::mesh_ptr const &mesh() {
        return _mesh;
    }

    render_target_updates_t &updates() {
        return this->_updates;
    }

    void clear_updates() {
        this->_updates.flags.reset();
        this->_mesh->renderable()->clear_updates();
        if (auto &effect = this->_effect->raw()) {
            renderable_effect::cast(effect)->clear_updates();
        }
    }

    MTLRenderPassDescriptor *renderPassDescriptor() {
        return *_render_pass_descriptor;
    }

    simd::float4x4 &projection_matrix() {
        return _projection_matrix;
    }

    bool push_encode_info(ui::render_stackable_ptr const &stackable) {
        if (!this->_is_size_enough()) {
            return false;
        }

        auto target = this->_weak_render_target.lock();
        if (auto const &metal_system = this->_metal_system) {
            metal_system->renderable()->push_render_target(stackable, target);
            return true;
        }
        return false;
    }

    void sync_scale_from_renderer(ui::renderer_ptr const &renderer, ui::render_target &target) {
        this->_scale_observer = renderer->chain_scale_factor().send_to(target.scale_factor_receiver()).sync();
    }

    ui::layout_guide_rect_ptr _layout_guide_rect = ui::layout_guide_rect::make_shared();
    chaining::value::holder_ptr<ui::effect_ptr> _effect = chaining::value::holder<ui::effect_ptr>::make_shared(nullptr);
    chaining::notifier_ptr<ui::effect_ptr> _effect_setter = chaining::notifier<ui::effect_ptr>::make_shared();
    chaining::value::holder_ptr<double> _scale_factor = chaining::value::holder<double>::make_shared(1.0);

   private:
    std::weak_ptr<render_target> _weak_render_target;
    ui::rect_plane_data_ptr _data = ui::rect_plane_data::make_shared(1);
    ui::mesh_ptr _mesh = ui::mesh::make_shared();
    ui::texture_ptr _src_texture;
    ui::texture_ptr _dst_texture;
    chaining::any_observer_ptr _src_texture_observer = nullptr;
    chaining::any_observer_ptr _dst_texture_observer = nullptr;
    objc_ptr<MTLRenderPassDescriptor *> _render_pass_descriptor;
    simd::float4x4 _projection_matrix;
    chaining::any_observer_ptr _scale_observer = nullptr;
    chaining::any_observer_ptr _rect_observer = nullptr;
    chaining::any_observer_ptr _effect_observer = nullptr;

    void _set_updated(ui::render_target_update_reason const reason) {
        this->_updates.set(reason);
    }

    bool _is_size_updated() {
        static render_target_updates_t const _size_updates = {ui::render_target_update_reason::scale_factor,
                                                              ui::render_target_update_reason::region};
        return this->_updates.and_test(_size_updates);
    }

    void _set_textures_to_effect() {
        if (auto const &effect = this->_effect->raw()) {
            renderable_effect::cast(effect)->set_textures(this->_src_texture, this->_dst_texture);
        }
    }

    bool _is_size_enough() {
        if (auto const &texture = this->_dst_texture) {
            ui::uint_size const actual_size = texture->actual_size();
            if (actual_size.width > 0 && actual_size.height > 0) {
                return true;
            }
        }
        return false;
    }

    ui::metal_system_ptr _metal_system = nullptr;

    render_target_updates_t _updates;
    std::vector<chaining::any_observer_ptr> _update_observers;
};

ui::render_target::render_target() : _impl(std::make_unique<impl>()) {
}

ui::layout_guide_rect_ptr &ui::render_target::layout_guide_rect() {
    return this->_impl->_layout_guide_rect;
}

void ui::render_target::set_scale_factor(double const scale_factor) {
    this->_impl->_scale_factor->set_value(scale_factor);
}

double ui::render_target::scale_factor() const {
    return this->_impl->_scale_factor->raw();
}

void ui::render_target::set_effect(ui::effect_ptr effect) {
    this->_impl->_effect_setter->notify(effect);
}

ui::effect_ptr const &ui::render_target::effect() {
    return this->_impl->_effect->raw();
}

std::shared_ptr<chaining::receiver<double>> ui::render_target::scale_factor_receiver() {
    return this->_impl->_scale_factor;
}

ui::renderable_render_target_ptr ui::render_target::renderable() {
    return std::dynamic_pointer_cast<renderable_render_target>(this->shared_from_this());
}

ui::metal_object_ptr ui::render_target::metal() {
    return std::dynamic_pointer_cast<ui::metal_object>(this->shared_from_this());
}

void ui::render_target::sync_scale_from_renderer(ui::renderer_ptr const &renderer) {
    this->_impl->sync_scale_from_renderer(renderer, *this);
}

void ui::render_target::_prepare(ui::render_target_ptr const &shared) {
    this->_impl->prepare(shared);
}

ui::setup_metal_result ui::render_target::metal_setup(std::shared_ptr<ui::metal_system> const &system) {
    return this->_impl->metal_setup(system);
}

ui::mesh_ptr const &ui::render_target::mesh() {
    return this->_impl->mesh();
}

ui::render_target_updates_t &ui::render_target::updates() {
    return this->_impl->updates();
}

void ui::render_target::clear_updates() {
    this->_impl->clear_updates();
}

MTLRenderPassDescriptor *ui::render_target::renderPassDescriptor() {
    return this->_impl->renderPassDescriptor();
}

simd::float4x4 &ui::render_target::projection_matrix() {
    return this->_impl->projection_matrix();
}

bool ui::render_target::push_encode_info(ui::render_stackable_ptr const &stackable) {
    return this->_impl->push_encode_info(stackable);
}

ui::render_target_ptr ui::render_target::make_shared() {
    auto shared = std::shared_ptr<render_target>(new render_target{});
    shared->_prepare(shared);
    return shared;
}
