//
//  yas_ui_matrix.cpp
//

#include "yas_ui_matrix.h"
#include <GLKit/GLKMath.h>

using namespace simd;
using namespace yas;

namespace yas {
static float4x4 to_float4x4(GLKMatrix4 const &m) {
    return float4x4{float4{m.m00, m.m01, m.m02, m.m03}, float4{m.m10, m.m11, m.m12, m.m13},
                    float4{m.m20, m.m21, m.m22, m.m23}, float4{m.m30, m.m31, m.m32, m.m33}};
}
}  // namespace yas

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
