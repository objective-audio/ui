//
//  yas_big_button_text_extension.h
//

#pragma once

#include "yas_ui.h"

namespace yas {
namespace sample {
    struct big_button_text_extension : base {
        class impl;

        explicit big_button_text_extension(ui::font_atlas atlas = nullptr);
        big_button_text_extension(std::nullptr_t);

        void set_status(ui::button_extension::method const);

        ui::strings_extension &strings_extension();
    };
}
}
