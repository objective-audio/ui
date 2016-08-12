//
//  yas_ui_big_button_extension.h
//

#pragma once

#include "yas_ui.h"

namespace yas {
namespace ui {
    class texture;
}

namespace sample {
    struct big_button_extension : public base {
        class impl;

        big_button_extension();
        big_button_extension(std::nullptr_t);

        void set_texture(ui::texture);

        ui::button_extension &button_extension();
    };
}
}
