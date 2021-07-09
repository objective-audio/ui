//
//  yas_ui_node_dependency.h
//

#pragma once

#include <simd/simd.h>
#include <ui/yas_ui_types.h>

#include <memory>

namespace yas::ui {
class renderer;

struct node_parent_interface {
    virtual ~node_parent_interface() = default;

    virtual simd::float4x4 const &matrix_as_parent() const = 0;

    point convert_position_as_parent(point const &loc) const {
        auto const loc4 = simd::float4x4(matrix_invert(this->matrix_as_parent())) * to_float4(loc.v);
        return {loc4.x, loc4.y};
    }

    [[nodiscard]] static std::shared_ptr<node_parent_interface> cast(
        std::shared_ptr<node_parent_interface> const &parent) {
        return parent;
    }
};
}  // namespace yas::ui
