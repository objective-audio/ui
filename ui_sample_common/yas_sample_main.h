//
//  yas_sample_main.h
//

#pragma once

#include <chaining/yas_chaining_umbrella.h>
#include <cpp_utils/yas_objc_ptr.h>
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
    ui::renderer_ptr renderer = ui::renderer::make_shared(
        ui::metal_system::make_shared(objc_ptr_with_move_object(MTLCreateSystemDefaultDevice()).object()));

    void setup();

   private:
    ui::font_atlas_ptr _font_atlas =
        ui::font_atlas::make_shared({.font_name = "TrebuchetMS-Bold",
                                     .font_size = 26.0f,
                                     .words = " abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890+-"});

    sample::touch_holder_ptr _touch_holder = sample::touch_holder::make_shared();
    sample::cursor_ptr _cursor = sample::cursor::make_shared();
    sample::inputted_text_ptr _inputted_text = sample::inputted_text::make_shared(_font_atlas);
    sample::draw_call_text_ptr _draw_call_text = sample::draw_call_text::make_shared(_font_atlas);
    sample::modifier_text_ptr _modifier_text =
        sample::modifier_text::make_shared(_font_atlas, _draw_call_text->strings()->frame_layout_guide_rect()->top());
    sample::bg_ptr _bg = sample::bg::make_shared();
    sample::cursor_over_planes_ptr _cursor_over_planes = sample::cursor_over_planes::make_shared();
    sample::big_button_ptr _big_button = sample::big_button::make_shared();
    sample::big_button_text_ptr _big_button_text = sample::big_button_text::make_shared(_font_atlas);
    sample::soft_keyboard_ptr _soft_keyboard = sample::soft_keyboard::make_shared(_font_atlas);
    sample::justified_points_ptr _justified_points = sample::justified_points::make_shared();

    std::shared_ptr<ui::batch> _batch = ui::batch::make_shared();

    chaining::any_observer_ptr _button_observer = nullptr;
    chaining::any_observer_ptr _keyboard_observer = nullptr;

    ui::node_ptr _render_target_node = ui::node::make_shared();
    ui::blur_ptr _blur = ui::blur::make_shared();
    ui::rect_plane_ptr _plane_on_target = ui::rect_plane::make_shared(1);
    chaining::any_observer_ptr _render_target_layout = nullptr;
};
}  // namespace yas::sample
