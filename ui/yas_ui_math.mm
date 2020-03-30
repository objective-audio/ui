//
//  yas_ui_math.cpp
//

#include "yas_ui_math.h"
#include <GLKit/GLKit.h>
#include <cmath>

using namespace yas;

float yas::roundf(float const value, double const scale) {
    return static_cast<float>(std::round(scale * value) / scale);
}

double yas::round(double const value, double const scale) {
    return std::round(scale * value) / scale;
}

float yas::ceilf(float const value, double const scale) {
    return static_cast<float>(std::ceil(scale * value) / scale);
}

double yas::ceil(double const value, double const scale) {
    return std::ceil(scale * value) / scale;
}

float yas::distance(ui::point const &src, ui::point const &dst) {
    float const x = src.x - dst.x;
    float const y = src.y - dst.y;
    return sqrt(x * x + y * y);
}
