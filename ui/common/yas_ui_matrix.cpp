//
//  yas_ui_matrix.cpp
//

#include "yas_ui_matrix.h"

using namespace simd;
using namespace yas;
using namespace yas::ui;

float4x4 matrix::scale(float const x, float const y) {
    return float4x4{float4{x, 0.0f, 0.0f, 0.0f}, float4{0.0f, y, 0.0f, 0.0f}, float4{0.0f, 0.0f, 1.0f, 0.0f},
                    float4{0.0f, 0.0f, 0.0f, 1.0f}};
}

float4x4 matrix::translation(float const x, float const y) {
    return float4x4{float4{1.0f, 0.0f, 0.0f, 0.0f}, float4{0.0f, 1.0f, 0.0f, 0.0f}, float4{0.0f, 0.0f, 1.0f, 0.0f},
                    float4{x, y, 0.0f, 1.0f}};
}

float4x4 matrix::rotation(float const degree) {
    float const radians = degree * M_PI / 180.0f;
    float const cos = cosf(radians);
    float const sin = sinf(radians);

    return float4x4{float4{cos, sin, 0.0f, 0.0f}, float4{-sin, cos, 0.0f, 0.0f}, float4{0.0f, 0.0f, 1.0f, 0.0f},
                    float4{0.0f, 0.0f, 0.0f, 1.0f}};
}

float4x4 matrix::ortho(float const left, float const right, float const bottom, float const top, float const near,
                       float const far) {
    float const ral = right + left;
    float const rsl = right - left;
    float const tab = top + bottom;
    float const tsb = top - bottom;
    float const fan = far + near;
    float const fsn = far - near;

    return float4x4{float4{2.0f / rsl, 0.0f, 0.0f, 0.0f}, float4{0.0f, 2.0f / tsb, 0.0f, 0.0f},
                    float4{0.0f, 0.0f, -2.0f / fsn, 0.0f}, float4{-ral / rsl, -tab / tsb, -fan / fsn, 1.0f}};
}
