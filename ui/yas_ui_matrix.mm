//
//  yas_ui_matrix.mm
//

#include <GLKit/GLKit.h>
#include "yas_ui_matrix.h"

using namespace simd;
using namespace yas;

namespace yas {
float4x4 to_float4x4(GLKMatrix4 const m) {
    return float4x4{float4{m.m00, m.m01, m.m02, m.m03}, float4{m.m10, m.m11, m.m12, m.m13},
                    float4{m.m20, m.m21, m.m22, m.m23}, float4{m.m30, m.m31, m.m32, m.m33}};
}
}

float4x4 ui::matrix::scale(float const x, float const y) {
    return to_float4x4(GLKMatrix4MakeScale(x, y, 1.0f));
}

float4x4 ui::matrix::translation(float const x, float const y) {
    return to_float4x4(GLKMatrix4MakeTranslation(x, y, 0.0f));
}

float4x4 ui::matrix::rotation(float const degree) {
    return to_float4x4(GLKMatrix4MakeZRotation(degree * M_PI / 180.0f));
}

float4x4 ui::matrix::ortho(float const left, float const right, float const bottom, float const top, float const near,
                           float const far) {
    return to_float4x4(GLKMatrix4MakeOrtho(left, right, bottom, top, near, far));
}