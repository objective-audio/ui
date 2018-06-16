//
//  yas_ui_render_target.mm
//

#include "yas_ui_render_target.h"
#include "yas_ui_effect.h"
#include "yas_ui_layout_guide.h"
#include "yas_ui_matrix.h"
#include "yas_ui_mesh.h"
#include "yas_ui_metal_texture.h"
#include "yas_ui_rect_plane.h"
#include "yas_ui_renderer.h"
#include "yas_ui_texture.h"
#include "yas_unless.h"

using namespace yas;

#pragma mark - render_target::impl

struct ui::render_target::impl : base::impl, renderable_render_target::impl, metal_object::impl {
    impl()
        : _src_texture(ui::texture{{.point_size = ui::uint_size::zero(),
                                    .scale_factor = 0.0,
                                    .draw_padding = 0,
                                    .usages = {ui::texture_usage::render_target, ui::texture_usage::shader_read},
                                    .pixel_format = ui::pixel_format::bgra8_unorm}}),
          _dst_texture(ui::texture{{.point_size = ui::uint_size::zero(),
                                    .scale_factor = 0.0,
                                    .draw_padding = 0,
                                    .usages = {ui::texture_usage::shader_write},
                                    .pixel_format = ui::pixel_format::bgra8_unorm}}) {
        this->_updates.flags.set();
        this->_render_pass_descriptor = make_objc_ptr([MTLRenderPassDescriptor new]);
        this->_mesh.set_mesh_data(this->_data.dynamic_mesh_data());
        this->_mesh.set_texture(this->_dst_texture);

        this->_effect_property.set_value(ui::effect::make_through_effect());
        this->_effect_flow =
            this->_effect_setter.begin()
                .map([](ui::effect const &effect) { return effect ?: ui::effect::make_through_effect(); })
                .receive(this->_effect_property.receiver())
                .end();

        this->_set_textures_to_effect();
    }

    void prepare(ui::render_target &target) {
        auto weak_target = to_weak(target);

        this->_src_texture_flow =
            this->_src_texture.begin_flow(ui::texture::method::metal_texture_changed)
                .perform([weak_target](ui::texture const &texture) {
                    if (ui::render_target target = weak_target.lock()) {
                        auto renderPassDescriptor = *target.impl_ptr<impl>()->_render_pass_descriptor;

                        if (ui::metal_texture const &metal_texture = texture.metal_texture()) {
                            auto color_desc = make_objc_ptr([MTLRenderPassColorAttachmentDescriptor new]);
                            auto colorDesc = *color_desc;
                            colorDesc.texture = metal_texture.texture();
                            colorDesc.loadAction = MTLLoadActionClear;
                            colorDesc.clearColor = MTLClearColorMake(0.0, 0.0, 0.0, 0.0);

                            [renderPassDescriptor.colorAttachments setObject:colorDesc atIndexedSubscript:0];
                        } else {
                            [renderPassDescriptor.colorAttachments setObject:nil atIndexedSubscript:0];
                        }
                    }
                })
                .end();

        this->_dst_texture_flow =
            this->_dst_texture.begin_flow(ui::texture::method::size_updated)
                .perform([weak_target](ui::texture const &texture) {
                    if (ui::render_target target = weak_target.lock()) {
                        target.impl_ptr<impl>()->_data.set_rect_tex_coords(
                            ui::uint_region{.origin = ui::uint_point::zero(), .size = texture.actual_size()}, 0);
                    }
                })
                .end();

        this->_update_flows.emplace_back(this->_effect_property.begin()
                                             .perform([weak_target](ui::effect const &) {
                                                 if (auto target = weak_target.lock()) {
                                                     target.impl_ptr<impl>()->_set_updated(
                                                         render_target_update_reason::effect);
                                                     target.impl_ptr<impl>()->_set_textures_to_effect();
                                                 }
                                             })
                                             .end());

        this->_update_flows.emplace_back(this->_scale_factor_property.begin()
                                             .perform([weak_target](double const &scale_factor) {
                                                 if (auto target = weak_target.lock()) {
                                                     auto imp = target.impl_ptr<impl>();
                                                     imp->_src_texture.set_scale_factor(scale_factor);
                                                     imp->_dst_texture.set_scale_factor(scale_factor);
                                                     target.impl_ptr<impl>()->_set_updated(
                                                         render_target_update_reason::scale_factor);
                                                 }
                                             })
                                             .end());

        this->_rect_flow = this->_layout_guide_rect.begin_flow()
                               .filter([weak_target](ui::region const &) { return !!weak_target; })
                               .perform([weak_target](ui::region const &region) {
                                   auto imp = weak_target.lock().impl_ptr<impl>();

                                   ui::uint_size size{.width = static_cast<uint32_t>(region.size.width),
                                                      .height = static_cast<uint32_t>(region.size.height)};

                                   imp->_src_texture.set_point_size(size);
                                   imp->_dst_texture.set_point_size(size);

                                   imp->_projection_matrix = ui::matrix::ortho(
                                       region.left(), region.right(), region.bottom(), region.top(), -1.0f, 1.0f);

                                   imp->_data.set_rect_position(region, 0);

                                   imp->_set_updated(render_target_update_reason::region);
                               })
                               .end();
    }

    ui::setup_metal_result metal_setup(ui::metal_system const &metal_system) override {
        if (!is_same(this->_metal_system, metal_system)) {
            this->_metal_system = metal_system;
        }

        if (auto ul = unless(this->_src_texture.metal().metal_setup(metal_system))) {
            return ul.value;
        }

        if (auto ul = unless(this->_dst_texture.metal().metal_setup(metal_system))) {
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

    bool push_encode_info(ui::render_stackable &stackable) override {
        if (!this->_is_size_enough()) {
            return false;
        }

        auto target = cast<ui::render_target>();
        if (auto &metal_system = this->_metal_system) {
            metal_system.renderable().push_render_target(stackable, target);
            return true;
        }
        return false;
    }

    void sync_scale_from_renderer(ui::renderer const &renderer, ui::render_target &target) {
        this->_scale_flow = renderer.begin_scale_factor_flow().receive(target.scale_factor_receiver()).sync();
    }

    ui::layout_guide_rect _layout_guide_rect;
    flow::property<ui::effect> _effect_property{ui::effect{nullptr}};
    flow::sender<ui::effect> _effect_setter;
    flow::property<double> _scale_factor_property{1.0};

   private:
    ui::rect_plane_data _data{1};
    ui::mesh _mesh;
    ui::texture _src_texture;
    ui::texture _dst_texture;
    flow::observer _src_texture_flow = nullptr;
    flow::observer _dst_texture_flow = nullptr;
    objc_ptr<MTLRenderPassDescriptor *> _render_pass_descriptor;
    simd::float4x4 _projection_matrix;
    flow::observer _scale_flow = nullptr;
    flow::observer _rect_flow = nullptr;
    flow::observer _effect_flow = nullptr;

    void _set_updated(ui::render_target_update_reason const reason) {
        this->_updates.set(reason);
    }

    bool _is_size_updated() {
        static render_target_updates_t const _size_updates = {ui::render_target_update_reason::scale_factor,
                                                              ui::render_target_update_reason::region};
        return this->_updates.and_test(_size_updates);
    }

    void _set_textures_to_effect() {
        if (auto &effect = this->_effect_property.value()) {
            effect.renderable().set_textures(this->_src_texture, this->_dst_texture);
        }
    }

    bool _is_size_enough() {
        if (auto const &texture = this->_dst_texture) {
            ui::uint_size const actual_size = texture.actual_size();
            if (actual_size.width > 0 && actual_size.height > 0) {
                return true;
            }
        }
        return false;
    }

    ui::metal_system _metal_system = nullptr;

    render_target_updates_t _updates;
    std::vector<flow::observer> _update_flows;
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
    impl_ptr<impl>()->_effect_setter.send_value(effect);
}

ui::effect const &ui::render_target::effect() const {
    return impl_ptr<impl>()->_effect_property.value();
}

flow::receiver<double> &ui::render_target::scale_factor_receiver() {
    return impl_ptr<impl>()->_scale_factor_property.receiver();
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

void ui::render_target::sync_scale_from_renderer(ui::renderer const &renderer) {
    impl_ptr<impl>()->sync_scale_from_renderer(renderer, *this);
}
