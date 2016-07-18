//
//  yas_sample_main.h
//

#pragma once

#include "yas_objc_ptr.h"
#include "yas_sample_bg.h"
#include "yas_sample_button_node.h"
#include "yas_sample_button_status_node.h"
#include "yas_sample_cursor_node.h"
#include "yas_sample_cursor_over_node.h"
#include "yas_sample_inputted_text.h"
#include "yas_sample_modifier_text.h"
#include "yas_sample_soft_keyboard.h"
#include "yas_sample_touch_holder.h"
#include "yas_ui.h"
#include "yas_ui_metal_system.h"

namespace yas {
namespace sample {
    struct main {
        ui::renderer renderer{ui::metal_system{make_objc_ptr(MTLCreateSystemDefaultDevice()).object()}};

        void setup();

       private:
        sample::touch_holder _touch_holder;
        sample::cursor_node _cursor_node;
        sample::inputted_text _inputted_text;
        sample::modifier_text _modifier_text;
        sample::bg _bg;
        sample::cursor_over_node _cursor_over_node;
        sample::button_node _button_node;
        sample::button_status_node _button_status_node;
        sample::soft_keyboard _soft_keyboard;

        ui::font_atlas _font_atlas{{.font_name = "TrebuchetMS-Bold",
                                    .font_size = 26.0f,
                                    .words = " abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890+-"}};

        ui::batch _batch;

        base _button_observer = nullptr;
        base _scale_observer = nullptr;
        base _keyboard_observer = nullptr;
    };
}
}
