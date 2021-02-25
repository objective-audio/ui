//
//  yas_ui_angle.cpp
//

#include "yas_ui_angle.h"

#include <cmath>

using namespace yas;
using namespace yas::ui;

bool angle::operator==(angle const &rhs) const {
    return this->degrees == rhs.degrees;
}

bool angle::operator!=(angle const &rhs) const {
    return this->degrees != rhs.degrees;
}

angle angle::operator+(angle const &rhs) const {
    return {this->degrees + rhs.degrees};
}

angle angle::operator-(angle const &rhs) const {
    return {this->degrees - rhs.degrees};
}

angle angle::operator*(float const &rhs) const {
    return {this->degrees * rhs};
}

angle angle::operator/(float const &rhs) const {
    return {this->degrees / rhs};
}

angle &angle::operator+=(angle const &rhs) {
    this->degrees += rhs.degrees;
    return *this;
}

angle &angle::operator-=(angle const &rhs) {
    this->degrees -= rhs.degrees;
    return *this;
}

angle &angle::operator*=(float const &rhs) {
    this->degrees *= rhs;
    return *this;
}

angle &angle::operator/=(float const &rhs) {
    this->degrees /= rhs;
    return *this;
}

angle angle::operator-() const {
    return {-this->degrees};
}

float angle::radians() const {
    return this->degrees * (static_cast<float>(M_PI) / 180.0f);
}

angle angle::shortest_from(angle const &from) const {
    float value = this->degrees - from.degrees;

    if (value == 0.0f) {
        return angle::zero();
    }

    value /= 360.0f;
    value -= std::trunc(value);

    if (value > 0.5f) {
        value -= 1.0f;
    } else if (value < -0.5f) {
        value += 1.0f;
    }

    return {value * 360.0f + from.degrees};
}

angle angle::shortest_to(angle const &to) const {
    return to.shortest_from(*this);
}

angle const &angle::zero() {
    static angle _zero_angle = angle{0.0f};
    return _zero_angle;
}

angle angle::make_radians(float const value) {
    return angle{value * (180.0f / static_cast<float>(M_PI))};
}

angle angle::make_degrees(float const value) {
    return angle{value};
}
