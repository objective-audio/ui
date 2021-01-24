//
//  yas_ui_render_target.h
//

#pragma once

#include <chaining/yas_chaining_umbrella.h>
#include <ui/yas_ui_effect.h>
#include <ui/yas_ui_layout_guide.h>
#include <ui/yas_ui_metal_protocol.h>
#include <ui/yas_ui_metal_system.h>
#include <ui/yas_ui_ptr.h>
#include <ui/yas_ui_render_target_protocol.h>
#include <ui/yas_ui_types.h>

namespace yas::ui {
struct render_target : metal_object, renderable_render_target {
    ui::layout_guide_rect_ptr &layout_guide_rect();

    void set_scale_factor(double const);
    double scale_factor() const;

    void set_effect(ui::effect_ptr);
    ui::effect_ptr const &effect() override;

    void sync_scale_from_renderer(ui::renderer_ptr const &);

    [[nodiscard]] static render_target_ptr make_shared();

   private:
    ui::layout_guide_rect_ptr _layout_guide_rect;
    chaining::value::holder_ptr<ui::effect_ptr> _effect;
    chaining::value::holder_ptr<double> _scale_factor;

    std::weak_ptr<render_target> _weak_render_target;
    ui::rect_plane_data_ptr _data;
    ui::mesh_ptr _mesh = ui::mesh::make_shared();
    ui::texture_ptr _src_texture;
    ui::texture_ptr _dst_texture;
    observing::canceller_ptr _src_texture_canceller = nullptr;
    observing::canceller_ptr _dst_texture_canceller = nullptr;
    objc_ptr<MTLRenderPassDescriptor *> _render_pass_descriptor;
    simd::float4x4 _projection_matrix;
    chaining::any_observer_ptr _scale_observer = nullptr;
    chaining::any_observer_ptr _rect_observer = nullptr;
    chaining::any_observer_ptr _effect_observer = nullptr;

    ui::metal_system_ptr _metal_system = nullptr;

    render_target_updates_t _updates;
    std::vector<chaining::any_observer_ptr> _update_observers;

    render_target();

    render_target(render_target const &) = delete;
    render_target(render_target &&) = delete;
    render_target &operator=(render_target const &) = delete;
    render_target &operator=(render_target &&) = delete;

    ui::setup_metal_result metal_setup(std::shared_ptr<ui::metal_system> const &) override;

    ui::mesh_ptr const &mesh() override;
    render_target_updates_t &updates() override;
    void clear_updates() override;
    MTLRenderPassDescriptor *renderPassDescriptor() override;
    simd::float4x4 &projection_matrix() override;
    bool push_encode_info(ui::render_stackable_ptr const &) override;

    void _set_updated(ui::render_target_update_reason const reason);
    bool _is_size_updated();
    void _set_textures_to_effect();
    bool _is_size_enough();
};
}  // namespace yas::ui
