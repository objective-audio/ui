//
//  yas_ui_big_button.h
//

#pragma once

#include "yas_ui.h"

namespace yas::ui {
class texture;
}

namespace yas::sample {
struct big_button : public base {
    class impl;

    big_button();
    big_button(std::nullptr_t);

    void set_texture(ui::texture);

    ui::button &button();
};
}  // namespace yas::sample
