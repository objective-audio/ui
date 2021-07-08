//
//  yas_ui_node_dependency.h
//

#pragma once

#include <simd/simd.h>

#include <memory>

namespace yas::ui {
class renderer;

struct node_parent_interface {
    virtual ~node_parent_interface() = default;

    virtual simd::float4x4 const &matrix_as_parent() const = 0;
};
}  // namespace yas::ui
