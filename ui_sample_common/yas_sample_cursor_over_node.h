//
//  yas_sample_cursor_over_node.h
//

#pragma once

#include "yas_ui.h"

namespace yas {
namespace sample {
    struct cursor_over_node : base {
        class impl;

        cursor_over_node();
        cursor_over_node(std::nullptr_t);

        ui::node &node();
    };
}
}
