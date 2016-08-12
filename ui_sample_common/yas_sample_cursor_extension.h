//
//  yas_sample_cursor_extension.h
//

#pragma once

#include "yas_ui.h"

namespace yas {
namespace sample {
    struct cursor_extension : base {
        class impl;

        cursor_extension();
        cursor_extension(std::nullptr_t);

        ui::node &node();
    };
}
}