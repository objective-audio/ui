//
//  yas_sample_main.h
//

#pragma once

#include "yas_objc_ptr.h"
#include "yas_sample_bg_extension.h"
#include "yas_sample_big_button_extension.h"
#include "yas_sample_big_button_text_extension.h"
#include "yas_sample_cursor_extension.h"
#include "yas_sample_cursor_over_planes_extension.h"
#include "yas_sample_inputted_text_extension.h"
#include "yas_sample_justified_points_extension.h"
#include "yas_sample_modifier_text_extension.h"
#include "yas_sample_soft_keyboard_extension.h"
#include "yas_sample_touch_holder_extension.h"
#include "yas_ui.h"
#include "yas_ui_metal_system.h"

namespace yas {
namespace sample {
    struct main {
        ui::renderer renderer{ui::metal_system{make_objc_ptr(MTLCreateSystemDefaultDevice()).object()}};

        void setup();

       private:
        sample::touch_holder_extension _touch_holder_ext;
        sample::cursor_extension _cursor_ext;
        sample::inputted_text_extension _inputted_text_ext;
        sample::modifier_text_extension _modifier_text_ext;
        sample::bg_extension _bg_ext;
        sample::cursor_over_planes_extension _cursor_over_planes_ext;
        sample::big_button_extension _big_button_ext;
        sample::big_button_text_extension _big_button_text_ext;
        sample::soft_keyboard_extension _soft_keyboard_ext;
        sample::justified_points_extension _justified_points_extension;

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
