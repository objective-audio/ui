//
//  yas_sample_cursor_over_planes_extension.h
//

#pragma once

#include "yas_ui.h"

namespace yas {
namespace sample {
    struct cursor_over_planes_extension : base {
        class impl;

        cursor_over_planes_extension();
        cursor_over_planes_extension(std::nullptr_t);

        ui::node &node();
    };
}
}
