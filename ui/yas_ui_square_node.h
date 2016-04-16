//
//  yas_ui_square_node.h
//

#pragma once

#include "yas_ui_node.h"
#include "yas_ui_shared_types.h"

namespace yas {
namespace ui {
    class dynamic_mesh_data;

    struct square_mesh_data {
        square_mesh_data(std::size_t const max_square_count);
        square_mesh_data(std::size_t const vertex_count, std::size_t const max_index_count);

        void write(std::size_t const square_idx,
                   std::function<void(ui::vertex2d_square_t &, ui::index_square_t &)> const &);
        void write(std::function<void(ui::vertex2d_square_t *, ui::index_square_t *)> const &);

        void set_square_count(std::size_t const);

        void set_square_index(std::size_t const index_idx, std::size_t const vertex_idx);
        void set_square_indices(std::vector<std::pair<std::size_t, std::size_t>> const &idx_pairs);
        void set_square_position(ui::float_region const &region, std::size_t const square_idx,
                                 simd::float4x4 const &matrix = matrix_identity_float4x4);
        void set_square_tex_coords(ui::uint_region const &pixel_region, std::size_t const square_idx);
        void set_square_vertex(const vertex2d_t *const in_ptr, std::size_t const square_idx,
                               simd::float4x4 const &matrix = matrix_identity_float4x4);

        ui::dynamic_mesh_data &mesh_data();

       private:
        ui::dynamic_mesh_data _mesh_data;
    };

    class square_node : public node {
        using super_class = node;

       public:
        explicit square_node(std::size_t const square_count);
        square_node(std::nullptr_t);

        ui::square_mesh_data &square_mesh_data();

       private:
        class impl;
    };
}
}
