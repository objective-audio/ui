//
//  yas_ui_renderer_dependency_cpp.h
//

#pragma once

namespace yas::ui {
struct renderable_view_look {
    virtual ~renderable_view_look() = default;

    [[nodiscard]] virtual simd::float4x4 const &projection_matrix() const = 0;
};
}  // namespace yas::ui
