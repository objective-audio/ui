//
//  yas_ui_shared_types.h
//

#pragma once

#include <simd/simd.h>

namespace yas {
namespace ui {
    struct vertex2d_t {
        simd::float2 position = 0.0f;
        simd::float2 tex_coord = 0.0f;
        simd::float4 color = 1.0f;
    };

    struct uniforms2d_t {
        simd::float4x4 matrix;
        simd::float4 color = 1.0f;
        bool use_mesh_color = false;
    } __attribute__((aligned(256)));
}  // namespace ui
}  // namespace yas
