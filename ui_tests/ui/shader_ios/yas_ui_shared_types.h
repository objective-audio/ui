//
//  yas_ui_shared_types.h
//

#pragma once

#include <simd/simd.h>

using namespace simd;

typedef struct {
    float2 position;
    float2 tex_coord;
} vertex2d_t;

typedef struct {
    float4x4 matrix;
    float4 color;
} __attribute__((aligned(16))) uniforms2d_t;
