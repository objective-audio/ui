//
//  yas_ui_render_target.h
//

#pragma once

#include <chaining/yas_chaining_umbrella.h>
#include "yas_ui_effect.h"
#include "yas_ui_layout_guide.h"
#include "yas_ui_metal_protocol.h"
#include "yas_ui_metal_system.h"
#include "yas_ui_ptr.h"
#include "yas_ui_render_target_protocol.h"
#include "yas_ui_types.h"

namespace yas::ui {
struct render_target : metal_object, renderable_render_target {
    ui::layout_guide_rect_ptr &layout_guide_rect();

    void set_scale_factor(double const);
    double scale_factor() const;

    void set_effect(ui::effect_ptr);
    ui::effect_ptr const &effect() override;

    std::shared_ptr<chaining::receiver<double>> scale_factor_receiver();

    void sync_scale_from_renderer(ui::renderer_ptr const &);

    [[nodiscard]] static render_target_ptr make_shared();

   private:
    class impl;

    std::unique_ptr<impl> _impl;

    render_target();

    render_target(render_target const &) = delete;
    render_target(render_target &&) = delete;
    render_target &operator=(render_target const &) = delete;
    render_target &operator=(render_target &&) = delete;

    void _prepare(render_target_ptr const &);

    ui::setup_metal_result metal_setup(std::shared_ptr<ui::metal_system> const &) override;

    ui::mesh_ptr const &mesh() override;
    render_target_updates_t &updates() override;
    void clear_updates() override;
    MTLRenderPassDescriptor *renderPassDescriptor() override;
    simd::float4x4 &projection_matrix() override;
    bool push_encode_info(ui::render_stackable_ptr const &) override;
};
}  // namespace yas::ui
