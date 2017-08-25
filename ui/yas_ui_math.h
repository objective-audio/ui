//
//  yas_ui_math.h
//

#pragma once

#include "yas_ui_types.h"

namespace yas {
float roundf(float const value, double const scale);
double round(double const value, double const scale);
float ceilf(float const value, double const scale);
double ceil(double const value, double const scale);

float distance(ui::point const &src, ui::point const &dst);

float degrees_from_radians(float const radians);
float radians_from_degrees(float const degrees);
}
