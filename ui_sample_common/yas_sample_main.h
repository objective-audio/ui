//
//  yas_sample_main.h
//

#pragma once

#include "yas_objc_ptr.h"
#include "yas_sample_bg_node.h"
#include "yas_sample_button_node.h"
#include "yas_sample_button_status_node.h"
#include "yas_sample_cursor_node.h"
#include "yas_sample_cursor_over_node.h"
#include "yas_sample_modifier_node.h"
#include "yas_sample_text_node.h"
#include "yas_sample_touch_holder.h"
#include "yas_ui.h"

namespace yas {
namespace sample {
    struct main {
        ui::renderer renderer{make_objc_ptr(MTLCreateSystemDefaultDevice()).object()};

        void setup();

       private:
        sample::touch_holder _touch_holder;
        sample::cursor_node _cursor_node;
        sample::text_node _text_node;
        sample::modifier_node _modifier_node;
        sample::bg_node _bg_node;
        sample::cursor_over_node _cursor_over_node;
        sample::button_node _button_node;
        sample::button_status_node _button_status_node;

        ui::font_atlas _font_atlas{{.font_name = "TrebuchetMS-Bold",
                                    .font_size = 26.0f,
                                    .words = " abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890+-"}};

        ui::batch _batch;

        base _button_observer = nullptr;
        base _scale_observer = nullptr;

        void _update_texture();
    };
}
}
