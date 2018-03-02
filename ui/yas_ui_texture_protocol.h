//
//  yas_ui_texture_protocol.h
//

#pragma once

#include "yas_ui_types.h"
#include <CoreGraphics/CoreGraphics.h>

namespace yas::ui {
class image;

using draw_handler_f = std::function<void(CGContextRef const)>;
using draw_pair_t = std::pair<uint_size, draw_handler_f>;
}
