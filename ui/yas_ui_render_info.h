//
//  yas_ui_render_info.h
//

#pragma once

#include <Metal/Metal.h>
#include <simd/simd.h>
#include <deque>
#include "yas_base.h"
#include "yas_ui_batch.h"
#include "yas_ui_collision_detector.h"
#include "yas_ui_render_encoder_protocol.h"

namespace yas {
namespace ui {
    struct render_info {
        simd::float4x4 matrix = matrix_identity_float4x4;
        simd::float4x4 mesh_matrix = matrix_identity_float4x4;
        ui::collision_detector collision_detector = nullptr;
        ui::render_encodable render_encodable = nullptr;
        std::vector<ui::batch> batches;
    };
}
}
