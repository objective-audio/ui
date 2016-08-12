//
//  yas_sample_modifier_text_extension.h
//

#pragma once

#include "yas_ui.h"

namespace yas {
namespace sample {
    struct modifier_text_extension : base {
        class impl;

        explicit modifier_text_extension(ui::font_atlas atlas = nullptr);
        modifier_text_extension(std::nullptr_t);

        ui::strings_extension &strings_extension();
    };
}
}
