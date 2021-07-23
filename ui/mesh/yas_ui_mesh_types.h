//
//  yas_ui_mesh_types.h
//

#pragma once

#include <ui/yas_ui_types.h>

namespace yas::ui {
struct mesh_args final {
    simd::float4 color = 1.0f;
    bool use_mesh_color = false;
    ui::primitive_type primitive_type = ui::primitive_type::triangle;
};
}  // namespace yas::ui
