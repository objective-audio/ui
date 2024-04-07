//
//  yas_ui_metal_view_utils.cpp
//

#include "yas_ui_metal_view_utils.h"

using namespace yas;
using namespace yas::ui;

ui::uint_size metal_view_utils::to_uint_size(CGSize size) {
    return {.width = static_cast<uint32_t>(size.width), .height = static_cast<uint32_t>(size.height)};
}
