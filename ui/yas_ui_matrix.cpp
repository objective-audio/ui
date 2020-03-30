//
//  yas_ui_matrix.cpp
//

#include "yas_ui_matrix.h"

using namespace simd;
using namespace yas;

float4x4 ui::matrix::scale(float const x, float const y) {
    return float4x4{float4{x, 0.0f, 0.0f, 0.0f}, float4{0.0f, y, 0.0f, 0.0f}, float4{0.0f, 0.0f, 1.0f, 0.0f},
                    float4{0.0f, 0.0f, 0.0f, 1.0f}};
}

float4x4 ui::matrix::translation(float const x, float const y) {
    return float4x4{float4{1.0f, 0.0f, 0.0f, 0.0f}, float4{0.0f, 1.0f, 0.0f, 0.0f}, float4{0.0f, 0.0f, 1.0f, 0.0f},
                    float4{x, y, 0.0f, 1.0f}};
}

float4x4 ui::matrix::rotation(float const degree) {
    float radians = degree * M_PI / 180.0f;
    float cos = cosf(radians);
    float sin = sinf(radians);

    return float4x4{float4{cos, sin, 0.0f, 0.0f}, float4{-sin, cos, 0.0f, 0.0f}, float4{0.0f, 0.0f, 1.0f, 0.0f},
                    float4{0.0f, 0.0f, 0.0f, 1.0f}};
}

float4x4 ui::matrix::ortho(float const left, float const right, float const bottom, float const top, float const near,
                           float const far) {
    float ral = right + left;
    float rsl = right - left;
    float tab = top + bottom;
    float tsb = top - bottom;
    float fan = far + near;
    float fsn = far - near;

    return float4x4{float4{2.0f / rsl, 0.0f, 0.0f, 0.0f}, float4{0.0f, 2.0f / tsb, 0.0f, 0.0f},
                    float4{0.0f, 0.0f, -2.0f / fsn, 0.0f}, float4{-ral / rsl, -tab / tsb, -fan / fsn, 1.0f}};
}
