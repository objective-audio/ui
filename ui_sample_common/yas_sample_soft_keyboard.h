//
//  yas_sample_soft_keyboard.h
//

#pragma once

#include <ui/yas_ui_umbrella.h>

namespace yas::sample {
struct soft_keyboard : base {
    class impl;

    explicit soft_keyboard(ui::font_atlas atlas);
    soft_keyboard(std::nullptr_t);

    void set_font_atlas(ui::font_atlas);

    ui::node &node();

    chaining::chain_unsync_t<std::string> chain() const;
};
}  // namespace yas::sample
