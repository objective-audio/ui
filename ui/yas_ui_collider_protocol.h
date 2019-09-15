//
//  yas_ui_collider_protocol.h
//

#pragma once

#include <simd/simd.h>
#include "yas_ui_ptr.h"

namespace yas::ui {
struct renderable_collider {
    virtual ~renderable_collider() = default;

    virtual simd::float4x4 const &matrix() const = 0;
    virtual void set_matrix(simd::float4x4 const &) = 0;

    static renderable_collider_ptr cast(renderable_collider_ptr const &renderable) {
        return renderable;
    }
};
}  // namespace yas::ui
