//
//  yas_ui_math.cpp
//

#include <cmath>
#include "yas_ui_math.h"

using namespace yas;

namespace yas {
float roundf(float const &v, double scale) {
    return static_cast<float>(std::round(scale * v) / scale);
}

double round(double const &v, double scale) {
    return std::round(scale * v) / scale;
}

float ceilf(float const &v, double scale) {
    return static_cast<float>(std::ceil(scale * v) / scale);
}

double ceil(double const &v, double scale) {
    return std::ceil(scale * v) / scale;
}
}
