//
//  yas_sample_cursor_node.h
//

#pragma once

#include "yas_ui.h"

namespace yas {
namespace sample {
    struct cursor_node : base {
        class impl;

        cursor_node();
        cursor_node(std::nullptr_t);

        ui::node &node();
    };
}
}