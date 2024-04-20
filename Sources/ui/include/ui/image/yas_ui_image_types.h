//
//  yas_ui_image_types.h
//

#pragma once

#include <ui/common/yas_ui_types.h>

namespace yas::ui {
struct image_args final {
    ui::uint_size point_size;
    double scale_factor = 1.0;
};
}  // namespace yas::ui
