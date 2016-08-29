//
//  yas_sample_modifier_text.h
//

#pragma once

#include "yas_ui.h"

namespace yas {
namespace sample {
    struct modifier_text : base {
        class impl;

        explicit modifier_text(ui::font_atlas atlas = nullptr);
        modifier_text(std::nullptr_t);

        ui::strings_extension &strings_extension();
    };
}
}
