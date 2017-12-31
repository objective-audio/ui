//
//  yas_ui_render_target.mm
//

#include "yas_ui_render_target.h"
#include "yas_property.h"
#include "yas_ui_rect_plane.h"
#include "yas_ui_mesh.h"
#include "yas_unless.h"
#include "yas_ui_texture.h"
#include "yas_ui_metal_texture.h"
#include "yas_ui_matrix.h"
#include "yas_ui_effect.h"
#include "yas_ui_layout_guide.h"

using namespace yas;

#pragma mark - render_target::impl

struct ui::render_target::impl : base::impl, renderable_render_target::impl, metal_object::impl {
    impl() {
        this->_updates.flags.set();
        this->_render_pass_descriptor = make_objc_ptr([MTLRenderPassDescriptor new]);
        this->_mesh.set_mesh_data(this->_data.dynamic_mesh_data());

        this->_effect_property.set_value(ui::effect::make_through_effect());
        this->_effect_property.set_limiter(
            [](ui::effect const &effect) { return effect ?: ui::effect::make_through_effect(); });
    }

    void prepare(ui::render_target &target) {
        auto weak_target = to_weak(target);

        this->_update_observers.emplace_back(this->_effect_property.subject().make_observer(
            property_method::did_change, [weak_target](auto const &context) {
                if (auto target = weak_target.lock()) {
                    target.impl_ptr<impl>()->_set_updated(render_target_update_reason::effect);
                    target.impl_ptr<impl>()->_set_texture_to_effect();
                }
            }));

        this->_update_observers.emplace_back(this->_scale_factor_property.subject().make_observer(
            property_method::did_change, [weak_target](auto const &context) {
                if (auto target = weak_target.lock()) {
                    target.impl_ptr<impl>()->_set_updated(render_target_update_reason::scale_factor);
                }
            }));

        this->_layout_guide_rect.set_value_changed_handler([weak_target](auto const &context) {
            if (auto target = weak_target.lock()) {
                target.impl_ptr<impl>()->_set_updated(render_target_update_reason::region);
            }
        });
    }

    ui::setup_metal_result metal_setup(ui::metal_system const &metal_system) override {
        if (!is_same(this->_metal_system, metal_system)) {
            this->_metal_system = metal_system;
            this->_mesh.set_texture(nullptr);
            this->_dst_texture = nullptr;
            this->_src_texture = nullptr;
            if (auto &effect = this->_effect_property.value()) {
                effect.renderable().set_textures(nullptr, nullptr);
            }
        }

        if (auto ul = unless(this->_update_textures())) {
            return ul.value;
        }

        return ui::setup_metal_result{nullptr};
    }

    ui::mesh &mesh() override {
        return _mesh;
    }

    ui::effect &effect() override {
        return this->_effect_property.value();
    }

    render_target_updates_t &updates() override {
        return this->_updates;
    }

    void clear_updates() override {
        this->_updates.flags.reset();
        this->_mesh.renderable().clear_updates();
        if (auto &effect = this->_effect_property.value()) {
            effect.renderable().clear_updates();
        }
    }

    MTLRenderPassDescriptor *renderPassDescriptor() override {
        return *_render_pass_descriptor;
    }

    simd::float4x4 &projection_matrix() override {
        return _projection_matrix;
    }

    void push_encode_info(ui::render_stackable &stackable) override {
        auto target = cast<ui::render_target>();
        if (auto &metal_system = this->_metal_system) {
            metal_system.renderable().push_render_target(stackable, target);
        }
    }

    ui::layout_guide_rect _layout_guide_rect;
    ui::rect_plane_data _data = ui::make_rect_plane_data(1);
    ui::mesh _mesh;
    ui::texture _src_texture = nullptr;
    ui::texture _dst_texture = nullptr;
    objc_ptr<MTLRenderPassDescriptor *> _render_pass_descriptor;
    simd::float4x4 _projection_matrix;
    property<std::nullptr_t, ui::effect> _effect_property{{.value = nullptr}};
    property<std::nullptr_t, double> _scale_factor_property{{.value = 1.0}};

   private:
    void _set_updated(ui::render_target_update_reason const reason) {
        this->_updates.set(reason);
    }

    bool _is_size_updated() {
        static render_target_updates_t const _size_updates = {ui::render_target_update_reason::scale_factor,
                                                              ui::render_target_update_reason::region};
        return this->_updates.and_test(_size_updates);
    }

    ui::setup_metal_result _update_textures() {
        if (!this->_metal_system || !this->_is_size_updated()) {
            return ui::setup_metal_result{nullptr};
        }

        auto const region = this->_layout_guide_rect.region();
        ui::uint_size size{.width = static_cast<uint32_t>(region.size.width),
                           .height = static_cast<uint32_t>(region.size.height)};

        this->_projection_matrix =
            ui::matrix::ortho(region.left(), region.right(), region.bottom(), region.top(), -1.0f, 1.0f);

        // for render_target
        if (auto texture_result =
                ui::make_texture({.metal_system = this->_metal_system,
                                  .point_size = size,
                                  .scale_factor = this->_scale_factor_property.value(),
                                  .draw_padding = 0,
                                  .usages = {ui::texture_usage::render_target, ui::texture_usage::shader_read},
                                  .pixel_format = ui::pixel_format::bgra8_unorm})) {
            this->_src_texture = std::move(texture_result.value());

            auto color_desc = make_objc_ptr([MTLRenderPassColorAttachmentDescriptor new]);
            auto colorDesc = *color_desc;
            colorDesc.texture = this->_src_texture.metal_texture().texture();
            colorDesc.loadAction = MTLLoadActionClear;
            colorDesc.clearColor = MTLClearColorMake(0.0, 0.0, 0.0, 0.0);

            auto renderPassDescriptor = *this->_render_pass_descriptor;
            [renderPassDescriptor.colorAttachments setObject:colorDesc atIndexedSubscript:0];
        } else {
            return ui::setup_metal_result{ui::setup_metal_error::create_texture_failed};
        }

        // for mesh
        if (auto texture_result = ui::make_texture({.metal_system = this->_metal_system,
                                                    .point_size = size,
                                                    .scale_factor = this->_scale_factor_property.value(),
                                                    .draw_padding = 0,
                                                    .usages = {ui::texture_usage::shader_write},
                                                    .pixel_format = ui::pixel_format::bgra8_unorm})) {
            this->_dst_texture = std::move(texture_result.value());
            auto &texture = this->_dst_texture;

            auto &data = this->_data;
            data.set_rect_position(this->_layout_guide_rect.region(), 0);
            data.set_rect_tex_coords(ui::uint_region{.origin = ui::uint_point::zero(), .size = texture.actual_size()},
                                     0);

            this->_mesh.set_texture(texture);
        } else {
            return ui::setup_metal_result{ui::setup_metal_error::create_texture_failed};
        }

        if (auto &effect = this->_effect_property.value()) {
            effect.renderable().set_textures(this->_src_texture, this->_dst_texture);
        }

        return ui::setup_metal_result{nullptr};
    }

    void _set_texture_to_effect() {
        if (auto &effect = this->_effect_property.value()) {
            effect.renderable().set_textures(this->_src_texture, this->_dst_texture);
        }
    }

    ui::metal_system _metal_system = nullptr;

    render_target_updates_t _updates;
    std::vector<base> _update_observers;
};

ui::render_target::render_target() : base(std::make_shared<impl>()) {
    impl_ptr<render_target::impl>()->prepare(*this);
}

ui::render_target::render_target(std::nullptr_t) : base(nullptr) {
}

ui::layout_guide_rect &ui::render_target::layout_guide_rect() {
    return impl_ptr<impl>()->_layout_guide_rect;
}

void ui::render_target::set_scale_factor(double const scale_factor) {
    impl_ptr<impl>()->_scale_factor_property.set_value(scale_factor);
}

double ui::render_target::scale_factor() const {
    return impl_ptr<impl>()->_scale_factor_property.value();
}

void ui::render_target::set_effect(ui::effect effect) {
    impl_ptr<impl>()->_effect_property.set_value(std::move(effect));
}

ui::effect const &ui::render_target::effect() const {
    return impl_ptr<impl>()->_effect_property.value();
}

ui::renderable_render_target &ui::render_target::renderable() {
    if (!this->_renderable) {
        this->_renderable = ui::renderable_render_target{impl_ptr<ui::renderable_render_target::impl>()};
    }
    return this->_renderable;
}

ui::metal_object &ui::render_target::metal() {
    if (!this->_metal_object) {
        this->_metal_object = ui::metal_object{impl_ptr<ui::metal_object::impl>()};
    }
    return this->_metal_object;
}
