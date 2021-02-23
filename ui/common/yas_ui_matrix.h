//
//  yas_ui_matrix.h
//

#pragma once

#include <simd/simd.h>

namespace yas::ui {
namespace matrix {
    simd::float4x4 scale(float const x, float const y);
    simd::float4x4 translation(float const x, float const y);
    simd::float4x4 rotation(float const degree);
    simd::float4x4 ortho(float const left, float const right, float const bottom, float const top, float const near,
                         float const far);
}  // namespace matrix
}  // namespace yas::ui
