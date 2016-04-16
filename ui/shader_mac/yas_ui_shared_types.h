//
//  yas_ui_shared_types.h
//

#pragma once

#include <simd/simd.h>

namespace yas {
namespace ui {
    using vertex2d_t = struct {
        simd::float2 position;
        simd::float2 tex_coord;
    };

    using uniforms2d_t = struct {
        simd::float4x4 matrix;
        simd::float4 color;
    } __attribute__((aligned(256)));
}
}
