//
//  yas_sample_soft_keyboard.h
//

#pragma once

#include "yas_ui.h"

namespace yas {
namespace sample {
    struct soft_keyboard : base {
        class impl;

        using subject_t = subject<soft_keyboard, std::string>;
        using observer_t = subject_t::observer_t;

        explicit soft_keyboard(ui::font_atlas atlas);
        soft_keyboard(std::nullptr_t);

        void set_font_atlas(ui::font_atlas);

        ui::node &node();

        subject_t &subject();
    };
}
}
