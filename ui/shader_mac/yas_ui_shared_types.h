//
//  yas_ui_shared_types.h
//

#pragma once

#include <simd/simd.h>

namespace yas {
namespace ui {
    struct vertex2d_t {
        simd::float2 position;
        simd::float2 tex_coord;
    };

    struct uniforms2d_t {
        simd::float4x4 matrix;
        simd::float4 color;
    } __attribute__((aligned(256)));
}
}
