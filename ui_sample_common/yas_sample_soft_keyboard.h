//
//  yas_sample_soft_keyboard.h
//

#pragma once

#include "yas_ui.h"

namespace yas::sample {
struct soft_keyboard : base {
    class impl;

    explicit soft_keyboard(ui::font_atlas atlas);
    soft_keyboard(std::nullptr_t);

    void set_font_atlas(ui::font_atlas);

    ui::node &node();

    chaining::chain<std::string, std::string, std::string, false> chain() const;
};
}  // namespace yas::sample
