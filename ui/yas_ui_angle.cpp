//
//  yas_ui_angle.cpp
//

#include "yas_ui_angle.h"
#include <cmath>

using namespace yas;

ui::angle::angle(radians_t rad)
    : radians(rad), degrees(degrees_t{.value = rad.value * (180.0f / static_cast<float>(M_PI))}) {
}

ui::angle::angle(degrees_t deg)
    : radians(radians_t{.value = deg.value * (static_cast<float>(M_PI) / 180.0f)}), degrees(deg) {
}

ui::angle ui::make_radians_angle(float const value) {
    return ui::angle{angle::radians_t{.value = value}};
}

ui::angle ui::make_degrees_angle(float const value) {
    return ui::angle{angle::degrees_t{.value = value}};
}
