//
//  yas_ui_angle.h
//

#pragma once

#include <cstdint>

namespace yas {
namespace ui {
    struct angle {
        struct radians_t {
            float const value = 0.0f;
        };

        struct degrees_t {
            float const value = 0.0f;
        };

        explicit angle(radians_t);
        explicit angle(degrees_t);

        radians_t const radians;
        degrees_t const degrees;
    };

    angle make_radians_angle(float const);
    angle make_degrees_angle(float const);
}
}
