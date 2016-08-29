//
//  yas_sample_main.h
//

#pragma once

#include "yas_objc_ptr.h"
#include "yas_sample_bg.h"
#include "yas_sample_big_button.h"
#include "yas_sample_big_button_text.h"
#include "yas_sample_collection_planes.h"
#include "yas_sample_cursor.h"
#include "yas_sample_cursor_over_planes.h"
#include "yas_sample_inputted_text.h"
#include "yas_sample_justified_points.h"
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
        sample::touch_holder _touch_holder_ext;
        sample::cursor _cursor_ext;
        sample::inputted_text _inputted_text_ext;
        sample::modifier_text _modifier_text_ext;
        sample::bg _bg;
        sample::cursor_over_planes _cursor_over_planes_ext;
        sample::big_button _big_button_ext;
        sample::big_button_text _big_button_text_ext;
        sample::soft_keyboard _soft_keyboard_ext;
        sample::justified_points _justified_points_ext;
        sample::collection_planes _collection_ext;

        ui::font_atlas _font_atlas{{.font_name = "TrebuchetMS-Bold",
                                    .font_size = 26.0f,
                                    .words = " abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890+-"}};

        ui::batch _batch;

        ui::button::observer_t _button_observer = nullptr;
        ui::renderer::observer_t _scale_observer = nullptr;
        sample::soft_keyboard::observer_t _keyboard_observer = nullptr;
    };
}
}
