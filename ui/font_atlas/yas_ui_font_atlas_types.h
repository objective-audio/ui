//
//  yas_ui_font_atlas_types.h
//

#pragma once

#include <ui/yas_ui_types.h>

namespace yas::ui {
struct font_atlas_args final {
    std::string font_name;
    double font_size;
    std::string words;
    std::shared_ptr<texture> texture = nullptr;
};
}  // namespace yas::ui
