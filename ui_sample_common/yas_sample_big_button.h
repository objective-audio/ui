//
//  yas_ui_big_button.h
//

#pragma once

#include <ui/yas_ui_umbrella.h>

namespace yas::ui {
class texture;
}

namespace yas::sample {
struct big_button : base {
    class impl;

    big_button();
    big_button(std::nullptr_t);

    void set_texture(ui::texture);

    std::shared_ptr<ui::button> &button();
};
}  // namespace yas::sample
