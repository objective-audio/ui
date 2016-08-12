//
//  yas_sample_soft_keyboard_extension.h
//

#pragma once

#include "yas_ui.h"

namespace yas {
namespace sample {
    struct soft_keyboard_extension : base {
        class impl;

        using subject_t = subject<soft_keyboard_extension, std::string>;

        explicit soft_keyboard_extension();
        soft_keyboard_extension(std::nullptr_t);

        void set_font_atlas(ui::font_atlas);

        ui::node &node();

        subject_t &subject();
    };
}
}
