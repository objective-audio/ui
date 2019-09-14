//
//  yas_sample_ptr.h
//

#pragma once

#include <memory>

namespace yas::sample {
class bg;
class big_button_text;
class big_button;
class cursor_over_planes;
class cursor;
class draw_call_text;
class inputted_text;
class justified_points;
class modifier_text;
class soft_keyboard;
class touch_holder;

using bg_ptr = std::shared_ptr<bg>;
using big_button_text_ptr = std::shared_ptr<big_button_text>;
using big_button_ptr = std::shared_ptr<big_button>;
using cursor_over_planes_ptr = std::shared_ptr<cursor_over_planes>;
using cursor_ptr = std::shared_ptr<cursor>;
using draw_call_text_ptr = std::shared_ptr<draw_call_text>;
using inputted_text_ptr = std::shared_ptr<inputted_text>;
using justified_points_ptr = std::shared_ptr<justified_points>;
using modifier_text_ptr = std::shared_ptr<modifier_text>;
using soft_keyboard_ptr = std::shared_ptr<soft_keyboard>;
using touch_holder_ptr = std::shared_ptr<touch_holder>;
}  // namespace yas::sample
