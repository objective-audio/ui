//
//  yas_ui_angle.h
//

#pragma once

#include <cstdint>

namespace yas {
namespace ui {
    struct angle {
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

        float radians() const;

        angle shortest_from(angle const &from) const;
        angle shortest_to(angle const &to) const;

        static angle const &zero();
    };

    angle make_radians_angle(float const);
    angle make_degrees_angle(float const);
}
}
