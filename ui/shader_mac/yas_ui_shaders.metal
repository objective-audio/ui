//
//  yas_ui_shaders.metal
//

#include <simd/simd.h>
#include <metal_stdlib>
#include "yas_ui_shared_types.h"

using namespace metal;
using namespace yas;

struct color_inout2d {
    float4 position[[position]];
    float4 color;
    float2 tex_coord[[user(texturecoord)]];
};

vertex color_inout2d vertex2d(device ui::vertex2d_t *vertex_array[[buffer(0)]],
                              constant ui::uniforms2d_t &uniforms[[buffer(1)]], unsigned int vid[[vertex_id]]) {
    color_inout2d out;

    float4 in_position = float4(float2(vertex_array[vid].position), 0.0, 1.0);
    out.position = uniforms.matrix * in_position;
    out.color = uniforms.color;
    out.tex_coord = vertex_array[vid].tex_coord;

    return out;
}

fragment float4 fragment2d(color_inout2d in[[stage_in]], texture2d<float> tex2D[[texture(0)]],
                           sampler sampler2D[[sampler(0)]]) {
    return tex2D.sample(sampler2D, in.tex_coord) * float4(float3(in.color.a), 1.0) * in.color;
}

fragment float4 fragment2d_without_texture(color_inout2d in[[stage_in]]) {
    return in.color;
}
