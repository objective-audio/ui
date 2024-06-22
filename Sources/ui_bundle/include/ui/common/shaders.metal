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

struct inputs {
    texture2d<float> tex2D;
    sampler sampler2D;
};

vertex color_inout2d vertex2d(device ui::vertex2d_t const *vertex_array[[buffer(0)]],
                              constant ui::uniforms2d_t &uniforms[[buffer(1)]], unsigned int vid[[vertex_id]]) {
    color_inout2d out;

    out.position = uniforms.matrix * float4(float2(vertex_array[vid].position), 0.0, 1.0);
    out.color = uniforms.use_mesh_color ? vertex_array[vid].color * uniforms.color : uniforms.color;
    out.tex_coord = vertex_array[vid].tex_coord;

    return out;
}

fragment float4 fragment2d_with_texture(color_inout2d in[[stage_in]], constant inputs &inputs[[buffer(0)]]) {
    return inputs.tex2D.sample(inputs.sampler2D, in.tex_coord) * in.color * float4(float3(in.color.a), 1.0);
}

fragment float4 fragment2d_without_texture(color_inout2d in[[stage_in]]) {
    return in.color * float4(float3(in.color.a), 1.0);
}
