//
//  yas_ui_math.cpp
//

#include <cmath>
#include "yas_ui_math.h"

using namespace yas;

namespace yas {
float roundf(float const value, double const scale) {
    return static_cast<float>(std::round(scale * value) / scale);
}

double round(double const value, double const scale) {
    return std::round(scale * value) / scale;
}

float ceilf(float const value, double const scale) {
    return static_cast<float>(std::ceil(scale * value) / scale);
}

double ceil(double const value, double const scale) {
    return std::ceil(scale * value) / scale;
}
}
