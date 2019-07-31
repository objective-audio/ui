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
#include "yas_sample_draw_call_text.hpp"
#include "yas_sample_inputted_text.h"
#include "yas_sample_justified_points.h"
#include "yas_sample_modifier_text.h"
#include "yas_sample_soft_keyboard.h"
#include "yas_sample_touch_holder.h"

namespace yas::sample {
struct main {
    ui::renderer renderer{ui::metal_system{objc_ptr_with_move_object(MTLCreateSystemDefaultDevice()).object()}};

    void setup();

   private:
    ui::font_atlas _font_atlas{{.font_name = "TrebuchetMS-Bold",
                                .font_size = 26.0f,
                                .words = " abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890+-"}};

    sample::touch_holder _touch_holder;
    sample::cursor _cursor;
    sample::inputted_text _inputted_text{_font_atlas};
    sample::draw_call_text _draw_call_text{_font_atlas};
    sample::modifier_text _modifier_text{_font_atlas, _draw_call_text.strings().frame_layout_guide_rect().top()};
    sample::bg _bg;
    sample::cursor_over_planes _cursor_over_planes;
    sample::big_button _big_button;
    sample::big_button_text _big_button_text{_font_atlas};
    sample::soft_keyboard _soft_keyboard{_font_atlas};
    sample::justified_points _justified_points;

    ui::batch _batch;

    chaining::any_observer_ptr _button_observer = nullptr;
    chaining::any_observer_ptr _keyboard_observer = nullptr;

    ui::node _render_target_node;
    ui::blur _blur;
    ui::rect_plane _plane_on_target{1};
    chaining::any_observer_ptr _render_target_layout = nullptr;
};
}  // namespace yas::sample
