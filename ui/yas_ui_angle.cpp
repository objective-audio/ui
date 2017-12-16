//
//  yas_ui_angle.cpp
//

#include "yas_ui_angle.h"
#include <cmath>

using namespace yas;

ui::angle::angle(radians_t radians)
    : radians(radians), degrees(degrees_t{.value = radians.value * (180.0f / static_cast<float>(M_PI))}) {
}

ui::angle::angle(degrees_t degrees)
    : radians(radians_t{.value = degrees.value * (static_cast<float>(M_PI) / 180.0f)}), degrees(degrees) {
}

ui::angle ui::angle::operator+(angle const &rhs) const {
    return ui::angle{radians_t{.value = this->radians.value + rhs.radians.value}};
}

ui::angle ui::angle::operator-(angle const &rhs) const {
    return ui::angle{radians_t{.value = this->radians.value - rhs.radians.value}};
}

ui::angle ui::make_radians_angle(float const value) {
    return ui::angle{angle::radians_t{.value = value}};
}

ui::angle ui::make_degrees_angle(float const value) {
    return ui::angle{angle::degrees_t{.value = value}};
}
