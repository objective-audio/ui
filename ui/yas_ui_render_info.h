//
//  yas_ui_render_info.h
//

#pragma once

#include <Metal/Metal.h>
#include <cpp_utils/yas_base.h>
#include <simd/simd.h>
#include <deque>
#include "yas_ui_batch.h"
#include "yas_ui_detector.h"
#include "yas_ui_metal_system.h"
#include "yas_ui_render_encoder_protocol.h"

namespace yas::ui {
struct render_info {
    simd::float4x4 matrix = matrix_identity_float4x4;
    simd::float4x4 mesh_matrix = matrix_identity_float4x4;
    ui::detector detector = nullptr;
    ui::render_encodable render_encodable = nullptr;
    ui::render_effectable render_effectable = nullptr;
    ui::render_stackable render_stackable = nullptr;
};
}  // namespace yas::ui
