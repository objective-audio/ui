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
    std::shared_ptr<detector> detector = nullptr;
    std::shared_ptr<render_encodable> render_encodable = nullptr;
    std::shared_ptr<render_effectable> render_effectable = nullptr;
    std::shared_ptr<render_stackable> render_stackable = nullptr;
};
}  // namespace yas::ui
