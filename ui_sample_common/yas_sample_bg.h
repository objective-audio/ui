//
//  yas_sample_bg_node.h
//

#pragma once

#include "yas_ui.h"

namespace yas {
namespace sample {
    struct bg : base {
        class impl;

        bg();
        bg(std::nullptr_t);

        ui::rect_plane_extension &rect_plane_extension();
    };
}
}
