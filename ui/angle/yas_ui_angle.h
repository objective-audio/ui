//
//  yas_ui_angle.h
//

#pragma once

#include <cstdint>

namespace yas::ui {
struct angle final {
    float degrees;

    bool operator==(angle const &rhs) const;
    bool operator!=(angle const &rhs) const;
    angle operator+(angle const &rhs) const;
    angle operator-(angle const &rhs) const;
    angle operator*(float const &rhs) const;
    angle operator/(float const &rhs) const;
    angle &operator+=(angle const &rhs);
    angle &operator-=(angle const &rhs);
    angle &operator*=(float const &rhs);
    angle &operator/=(float const &rhs);
    angle operator-() const;

    [[nodiscard]] float radians() const;

    [[nodiscard]] angle shortest_from(angle const &from) const;
    [[nodiscard]] angle shortest_to(angle const &to) const;

    static angle const &zero();
    static angle make_radians(float const);
    static angle make_degrees(float const);
};
}  // namespace yas::ui
