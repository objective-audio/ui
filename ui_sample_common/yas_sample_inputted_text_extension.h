//
//  yas_sample_text_node_extension.h
//

#pragma once

#include "yas_ui.h"

namespace yas {
namespace sample {
    struct inputted_text_extension : base {
        class impl;

        explicit inputted_text_extension(ui::font_atlas atlas = nullptr);
        inputted_text_extension(std::nullptr_t);

        void append_text(std::string text);

        ui::strings_extension &strings_extension();
    };
}
}
