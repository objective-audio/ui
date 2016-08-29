//
//  yas_big_button_text.h
//

#pragma once

#include "yas_ui.h"

namespace yas {
namespace sample {
    struct big_button_text : base {
        class impl;

        explicit big_button_text(ui::font_atlas atlas = nullptr);
        big_button_text(std::nullptr_t);

        void set_status(ui::button_extension::method const);

        ui::strings_extension &strings_extension();
    };
}
}
