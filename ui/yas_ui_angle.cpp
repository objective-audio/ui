//
//  yas_ui_angle.cpp
//

#include "yas_ui_angle.h"
#include <cmath>

using namespace yas;

bool ui::angle::operator==(angle const &rhs) const {
    return this->degrees == rhs.degrees;
}

bool ui::angle::operator!=(angle const &rhs) const {
    return this->degrees != rhs.degrees;
}

ui::angle ui::angle::operator+(angle const &rhs) const {
    return ui::angle{this->degrees + rhs.degrees};
}

ui::angle ui::angle::operator-(angle const &rhs) const {
    return ui::angle{this->degrees - rhs.degrees};
}

ui::angle &ui::angle::operator+=(angle const &rhs) {
    this->degrees += rhs.degrees;
    return *this;
}

ui::angle &ui::angle::operator-=(angle const &rhs) {
    this->degrees -= rhs.degrees;
    return *this;
}

float ui::angle::radians() const {
    return this->degrees * (static_cast<float>(M_PI) / 180.0f);
}

ui::angle ui::angle::zero() {
    static angle _zero_angle = ui::angle{0.0f};
    return _zero_angle;
}

ui::angle ui::make_radians_angle(float const value) {
    return ui::angle{value * (180.0f / static_cast<float>(M_PI))};
}

ui::angle ui::make_degrees_angle(float const value) {
    return ui::angle{value};
}
