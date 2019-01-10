//
//  yas_sample_modifier_text.h
//

#pragma once

#include <ui/yas_ui_umbrella.h>

namespace yas::sample {
struct modifier_text : base {
    class impl;

    explicit modifier_text(ui::font_atlas, ui::layout_guide bottom_guide);
    modifier_text(std::nullptr_t);

    ui::strings &strings();
};
}  // namespace yas::sample
