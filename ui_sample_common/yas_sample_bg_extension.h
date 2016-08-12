//
//  yas_sample_bg_extension.h
//

#pragma once

#include "yas_ui.h"

namespace yas {
namespace sample {
    struct bg_extension : base {
        class impl;

        bg_extension();
        bg_extension(std::nullptr_t);

        ui::rect_plane_extension &rect_plane_extension();
    };
}
}
