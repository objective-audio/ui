//
//  yas_sample_text_node.h
//

#pragma once

#include "yas_ui.h"

namespace yas {
namespace sample {
    struct text_node : base {
        class impl;

        explicit text_node(ui::font_atlas atlas = nullptr);
        text_node(std::nullptr_t);

        ui::strings &strings();
    };
}
}
