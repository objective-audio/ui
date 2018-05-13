//
//  yas_sample_draw_call_text.hpp
//

#pragma once

#include "yas_ui.h"

namespace yas::sample {
struct draw_call_text : base {
    class impl;

    explicit draw_call_text(ui::font_atlas atlas);
    draw_call_text(std::nullptr_t);

    ui::strings &strings();
};
}  // namespace yas::sample
