//
//  yas_ui_render_target.h
//

#pragma once

#include <observing/yas_observing_umbrella.h>
#include <ui/yas_ui_common_dependency.h>
#include <ui/yas_ui_effect.h>
#include <ui/yas_ui_layout_guide.h>
#include <ui/yas_ui_metal_dependency.h>
#include <ui/yas_ui_metal_system.h>
#include <ui/yas_ui_render_target_types.h>
#include <ui/yas_ui_renderer_dependency.h>
#include <ui/yas_ui_types.h>

namespace yas::ui {
struct render_target : metal_object, renderable_render_target {
    std::shared_ptr<layout_region_guide> &layout_guide();

    void set_scale_factor(double const);
    [[nodiscard]] double scale_factor() const;

    void set_effect(std::shared_ptr<ui::effect>);
    [[nodiscard]] std::shared_ptr<ui::effect> const &effect() const override;

    [[nodiscard]] static std::shared_ptr<render_target> make_shared(
        std::shared_ptr<ui::view_look_scale_factor_interface> const &);

   private:
    std::shared_ptr<ui::layout_region_guide> _layout_guide;
    std::shared_ptr<ui::effect> _effect;
    double _scale_factor;

    std::shared_ptr<rect_plane_data> _data;
    std::shared_ptr<ui::mesh> _mesh = ui::mesh::make_shared();
    std::shared_ptr<texture> _src_texture;
    std::shared_ptr<texture> _dst_texture;
    objc_ptr<MTLRenderPassDescriptor *> _render_pass_descriptor;
    simd::float4x4 _projection_matrix;
    observing::cancellable_ptr _scale_canceller = nullptr;
    observing::canceller_pool _pool;

    std::shared_ptr<metal_system> _metal_system = nullptr;

    render_target_updates_t _updates;

    render_target(std::shared_ptr<ui::view_look_scale_factor_interface> const &);

    render_target(render_target const &) = delete;
    render_target(render_target &&) = delete;
    render_target &operator=(render_target const &) = delete;
    render_target &operator=(render_target &&) = delete;

    ui::setup_metal_result metal_setup(std::shared_ptr<ui::metal_system> const &) override;

    std::shared_ptr<ui::mesh> const &mesh() const override;
    render_target_updates_t const &updates() const override;
    void clear_updates() override;
    MTLRenderPassDescriptor *renderPassDescriptor() const override;
    simd::float4x4 const &projection_matrix() const override;
    bool push_encode_info(std::shared_ptr<render_stackable> const &) override;

    void _set_updated(ui::render_target_update_reason const reason);
    bool _is_size_updated();
    void _set_textures_to_effect();
    bool _is_size_enough();
};
}  // namespace yas::ui
