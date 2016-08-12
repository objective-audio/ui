//
//  yas_sample_text_node.h
//

#pragma once

#include "yas_ui.h"

namespace yas {
namespace sample {
    struct inputted_text : base {
        class impl;

        explicit inputted_text(ui::font_atlas atlas = nullptr);
        inputted_text(std::nullptr_t);

        void append_text(std::string text);

        ui::strings_extension &strings_extension();
    };
}
}
