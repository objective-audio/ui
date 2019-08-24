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
struct render_target {
    class impl;

    ui::layout_guide_rect_ptr &layout_guide_rect();

    void set_scale_factor(double const);
    double scale_factor() const;

    void set_effect(ui::effect_ptr);
    ui::effect_ptr const &effect() const;

    std::shared_ptr<chaining::receiver<double>> scale_factor_receiver();

    ui::renderable_render_target &renderable();
    ui::metal_object &metal();

    void sync_scale_from_renderer(ui::renderer_ptr const &);

    [[nodiscard]] static render_target_ptr make_shared();

   private:
    std::shared_ptr<impl> _impl;

    ui::metal_object _metal_object = nullptr;
    ui::renderable_render_target _renderable = nullptr;

    render_target();

    render_target(render_target const &) = delete;
    render_target(render_target &&) = delete;
    render_target &operator=(render_target const &) = delete;
    render_target &operator=(render_target &&) = delete;

    void _prepare(render_target_ptr const &);
};
}  // namespace yas::ui
