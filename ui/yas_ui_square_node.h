//
//  yas_ui_square_node.h
//

#pragma once

#include "yas_ui_node.h"

namespace yas {
namespace ui {
    class square_node : public node {
        using super_class = node;

       public:
        explicit square_node(std::size_t const square_count);
        square_node(std::nullptr_t);

        void set_square_index(std::size_t const element_idx, std::size_t const square_idx);
        void set_square_indices(std::vector<std::pair<std::size_t, std::size_t>> const &idx_pairs);
        void set_square_position(ui::float_region const &region, std::size_t const square_idx,
                                 simd::float4x4 const &matrix = matrix_identity_float4x4);
        void set_square_tex_coords(ui::uint_region const &pixel_region, std::size_t const square_idx);
        void set_square_vertex(const vertex2d_t *const in_ptr, std::size_t const square_idx,
                               simd::float4x4 const &matrix = matrix_identity_float4x4);

        ui::dynamic_mesh_data &mesh_data();

       private:
        class impl;
    };
}
}
