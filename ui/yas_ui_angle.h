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
        angle &operator+=(angle const &rhs);
        angle &operator-=(angle const &rhs);

        float radians() const;
    };

    angle make_radians_angle(float const);
    angle make_degrees_angle(float const);
}
}
