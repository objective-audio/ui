//
//  yas_ui_font_atlas_types.h
//

#pragma once

#include <ui/yas_ui_ptr.h>

#include <string>

namespace yas::ui {
struct font_atlas_args {
    std::string font_name;
    double font_size;
    std::string words;
    ui::texture_ptr texture = nullptr;
};
}  // namespace yas::ui
