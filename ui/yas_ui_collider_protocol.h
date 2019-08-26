//
//  yas_ui_collider_protocol.h
//

#pragma once

#include <simd/simd.h>

namespace yas::ui {
struct renderable_collider {
    virtual ~renderable_collider() = default;

    virtual simd::float4x4 const &matrix() const = 0;
    virtual void set_matrix(simd::float4x4 const &) = 0;
};

using renderable_collider_ptr = std::shared_ptr<renderable_collider>;
}  // namespace yas::ui
