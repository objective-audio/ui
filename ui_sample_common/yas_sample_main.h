//
//  yas_sample_main.h
//

#pragma once

#include <cpp_utils/yas_objc_ptr.h>
#include <observing/yas_observing_umbrella.h>
#include <ui/yas_ui_metal_system.h>
#include <ui/yas_ui_umbrella.h>

#include "yas_sample_bg.h"
#include "yas_sample_big_button.h"
#include "yas_sample_big_button_text.h"
#include "yas_sample_cursor.h"
#include "yas_sample_cursor_over_planes.h"
#include "yas_sample_draw_call_text.h"
#include "yas_sample_inputted_text.h"
#include "yas_sample_justified_points.h"
#include "yas_sample_modifier_text.h"
#include "yas_sample_soft_keyboard.h"
#include "yas_sample_touch_holder.h"

namespace yas::sample {
struct main {
    std::shared_ptr<ui::view_look> const view_look;
    std::shared_ptr<ui::metal_system> const metal_system;
    std::shared_ptr<ui::node> const root_node = ui::node::make_shared(view_look);
    std::shared_ptr<ui::detector> const detector = ui::detector::make_shared();
    std::shared_ptr<ui::event_manager> const event_manager = ui::event_manager::make_shared();
    std::shared_ptr<ui::action_manager> const action_manager = ui::action_manager::make_shared();
    std::shared_ptr<ui::renderer> const renderer =
        ui::renderer::make_shared(metal_system, view_look, root_node, detector, action_manager);

    void setup();

    [[nodiscard]] static std::shared_ptr<main> make_shared(std::shared_ptr<ui::view_look> const &,
                                                           std::shared_ptr<ui::metal_system> const &);

   private:
    std::shared_ptr<ui::font_atlas> const _font_atlas =
        ui::font_atlas::make_shared({.font_name = "TrebuchetMS-Bold",
                                     .font_size = 26.0f,
                                     .words = " abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890+-"});

    sample::touch_holder_ptr const _touch_holder = sample::touch_holder::make_shared(event_manager, action_manager);
    sample::cursor_ptr const _cursor = sample::cursor::make_shared(event_manager, action_manager);
    sample::inputted_text_ptr const _inputted_text =
        sample::inputted_text::make_shared(_font_atlas, event_manager, view_look->safe_area_layout_guide());
    sample::draw_call_text_ptr const _draw_call_text =
        sample::draw_call_text::make_shared(_font_atlas, metal_system, view_look->safe_area_layout_guide());
    sample::modifier_text_ptr const _modifier_text =
        sample::modifier_text::make_shared(_font_atlas, event_manager, view_look->safe_area_layout_guide(),
                                           _draw_call_text->strings()->preferred_layout_guide()->top());
    sample::bg_ptr const _bg = sample::bg::make_shared(view_look->safe_area_layout_guide());
    sample::cursor_over_planes_ptr const _cursor_over_planes =
        sample::cursor_over_planes::make_shared(event_manager, action_manager, detector);
    sample::big_button_ptr const _big_button = sample::big_button::make_shared(event_manager, detector);
    sample::big_button_text_ptr const _big_button_text = sample::big_button_text::make_shared(_font_atlas);
    sample::soft_keyboard_ptr const _soft_keyboard = sample::soft_keyboard::make_shared(
        _font_atlas, event_manager, action_manager, detector, view_look->safe_area_layout_guide());
    sample::justified_points_ptr const _justified_points =
        sample::justified_points::make_shared(view_look->view_layout_guide());

    std::shared_ptr<ui::batch> const _batch = ui::batch::make_shared();

    std::shared_ptr<ui::node> const _render_target_node = ui::node::make_shared();
    std::shared_ptr<ui::blur> const _blur = ui::blur::make_shared();
    std::shared_ptr<ui::rect_plane> const _plane_on_target = ui::rect_plane::make_shared(1);

    observing::canceller_pool _pool;

    main(std::shared_ptr<ui::view_look> const &, std::shared_ptr<ui::metal_system> const &);
};
}  // namespace yas::sample
