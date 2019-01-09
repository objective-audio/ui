//
//  yas_sample_inputted_text.h
//

#pragma once

#include <ui/yas_ui_umbrella.h>

namespace yas::sample {
struct inputted_text : base {
    class impl;

    explicit inputted_text(ui::font_atlas atlas);
    inputted_text(std::nullptr_t);

    void append_text(std::string text);

    ui::strings &strings();
};
}  // namespace yas::sample
