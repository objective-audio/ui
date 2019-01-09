//
//  yas_big_button_text.h
//

#pragma once

#include <ui/yas_ui_umbrella.h>

namespace yas::sample {
struct big_button_text : base {
    class impl;

    explicit big_button_text(ui::font_atlas atlas);
    big_button_text(std::nullptr_t);

    void set_status(ui::button::method const);

    ui::strings &strings();
};
}  // namespace yas::sample
