//
//  yas_ui_math.cpp
//

#include <cmath>
#include "yas_ui_math.h"
#include <GLKit/GLKit.h>

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
    return GLKVector2Distance(GLKVector2Make(src.x, src.y), GLKVector2Make(dst.x, dst.y));
}
