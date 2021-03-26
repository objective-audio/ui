//
//  yas_ui_render_info.h
//

#pragma once

#include <Metal/Metal.h>
#include <simd/simd.h>
#include <ui/yas_ui_batch.h>
#include <ui/yas_ui_detector.h>
#include <ui/yas_ui_metal_system.h>
#include <ui/yas_ui_render_info_dependency.h>

#include <deque>

namespace yas::ui {
struct render_info {
    simd::float4x4 matrix = matrix_identity_float4x4;
    simd::float4x4 mesh_matrix = matrix_identity_float4x4;
    ui::detector_ptr detector = nullptr;
    ui::render_encodable_ptr render_encodable = nullptr;
    ui::render_effectable_ptr render_effectable = nullptr;
    ui::render_stackable_ptr render_stackable = nullptr;
};
}  // namespace yas::ui