//
//  yas_sample_main.h
//

#pragma once

#include <cpp_utils/yas_objc_ptr.h>
#include <observing/yas_observing_umbrella.h>
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
    std::shared_ptr<ui::standard> const standard;

    void setup();

    [[nodiscard]] static std::shared_ptr<main> make_shared(std::shared_ptr<ui::view_look> const &,
                                                           std::shared_ptr<ui::metal_system> const &);

   private:
    std::shared_ptr<ui::texture> const _texture =
        ui::texture::make_shared({.point_size = {1024, 1024}}, standard->view_look());
    std::shared_ptr<ui::font_atlas> const _font_atlas =
        ui::font_atlas::make_shared({.font_name = "TrebuchetMS-Bold",
                                     .font_size = 26.0f,
                                     .words = " abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890+-"},
                                    _texture);

    sample::touch_holder_ptr const _touch_holder =
        sample::touch_holder::make_shared(standard->event_manager(), standard->action_manager());
    sample::cursor_ptr const _cursor =
        sample::cursor::make_shared(standard->event_manager(), standard->action_manager());
    sample::inputted_text_ptr const _inputted_text = sample::inputted_text::make_shared(
        _font_atlas, standard->event_manager(), standard->view_look()->safe_area_layout_guide());
    sample::draw_call_text_ptr const _draw_call_text = sample::draw_call_text::make_shared(
        _font_atlas, standard->metal_system(), standard->view_look()->safe_area_layout_guide());
    sample::modifier_text_ptr const _modifier_text = sample::modifier_text::make_shared(
        _font_atlas, standard->event_manager(), standard->view_look()->safe_area_layout_guide(),
        _draw_call_text->strings()->preferred_layout_guide()->top());
    sample::bg_ptr const _bg = sample::bg::make_shared(standard->view_look()->safe_area_layout_guide());
    sample::cursor_over_planes_ptr const _cursor_over_planes = sample::cursor_over_planes::make_shared(
        standard->event_manager(), standard->action_manager(), standard->detector());
    sample::big_button_ptr const _big_button =
        sample::big_button::make_shared(standard->event_manager(), standard->detector(), standard->renderer());
    sample::big_button_text_ptr const _big_button_text = sample::big_button_text::make_shared(_font_atlas);
    sample::soft_keyboard_ptr const _soft_keyboard = sample::soft_keyboard::make_shared(
        _font_atlas, standard->event_manager(), standard->action_manager(), standard->detector(), standard->renderer(),
        standard->view_look()->safe_area_layout_guide());
    sample::justified_points_ptr const _justified_points =
        sample::justified_points::make_shared(standard->view_look()->view_layout_guide());

    std::shared_ptr<ui::batch> const _batch = ui::batch::make_shared();

    std::shared_ptr<ui::node> const _render_target_node = ui::node::make_shared();
    std::shared_ptr<ui::blur> const _blur = ui::blur::make_shared();
    std::shared_ptr<ui::rect_plane> const _plane_on_target = ui::rect_plane::make_shared(1);

    observing::canceller_pool _pool;

    main(std::shared_ptr<ui::view_look> const &, std::shared_ptr<ui::metal_system> const &);
};
}  // namespace yas::sample
