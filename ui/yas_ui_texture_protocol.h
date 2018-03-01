//
//  yas_ui_texture_protocol.h
//

#pragma once

#include "yas_ui_types.h"

namespace yas::ui {
class image;

using image_handler = std::function<void(ui::image &image)>;
using image_pair_t = std::pair<uint_size, image_handler>;
}
