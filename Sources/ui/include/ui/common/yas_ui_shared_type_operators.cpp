//
//  yas_ui_shared_type_operators.cpp
//

#include "yas_ui_shared_type_operators.hpp"

#include <Accelerate/Accelerate.h>

using namespace yas;
using namespace yas::ui;

bool operator==(vertex2d_t const &lhs, vertex2d_t const &rhs) {
    return simd_equal(lhs.position, rhs.position) && simd_equal(lhs.tex_coord, rhs.tex_coord) &&
           simd_equal(lhs.color, rhs.color);
}

bool operator!=(yas::ui::vertex2d_t const &lhs, yas::ui::vertex2d_t const &rhs) {
    return !(lhs == rhs);
}

bool operator==(yas::ui::uniforms2d_t const &lhs, yas::ui::uniforms2d_t const &rhs) {
    return lhs.use_mesh_color == rhs.use_mesh_color && simd_equal(lhs.color, rhs.color) &&
           simd_equal(lhs.matrix, rhs.matrix);
}

bool operator!=(yas::ui::uniforms2d_t const &lhs, yas::ui::uniforms2d_t const &rhs) {
    return !(lhs == rhs);
}
