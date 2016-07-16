//
//  yas_sample_modifier_node.h
//

#pragma once

#include "yas_ui.h"

namespace yas {
namespace sample {
    struct modifier_node : base {
        class impl;

        explicit modifier_node(ui::font_atlas atlas = nullptr);
        modifier_node(std::nullptr_t);

        ui::strings &strings();
    };
}
}
