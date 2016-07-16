//
//  yas_ui_square.h
//

#pragma once

#include <vector>
#include "yas_ui_mesh_data.h"
#include "yas_ui_types.h"

namespace yas {
namespace ui {
    class node;

    struct square_mesh_data {
        explicit square_mesh_data(ui::dynamic_mesh_data mesh_data);

        void write(std::function<void(ui::vertex2d_square_t *, ui::index2d_square_t *)> const &);
        void write_vertex(std::size_t const square_idx, std::function<void(ui::vertex2d_square_t &)> const &);
        void write_index(std::size_t const square_idx, std::function<void(ui::index2d_square_t &)> const &);

        std::size_t max_square_count() const;
        void set_square_count(std::size_t const);

        void set_square_index(std::size_t const index_idx, std::size_t const vertex_idx);
        void set_square_indices(std::vector<std::pair<std::size_t, std::size_t>> const &idx_pairs);
        void set_square_position(ui::float_region const &region, std::size_t const square_idx,
                                 simd::float4x4 const &matrix = matrix_identity_float4x4);
        void set_square_color(simd::float4 const &color, std::size_t const square_idx);
        void set_square_tex_coords(ui::uint_region const &pixel_region, std::size_t const square_idx);
        void set_square_vertex(const vertex2d_t *const in_ptr, std::size_t const square_idx,
                               simd::float4x4 const &matrix = matrix_identity_float4x4);

        ui::dynamic_mesh_data &dynamic_mesh_data();

       private:
        ui::dynamic_mesh_data _dynamic_mesh_data;
    };

    square_mesh_data make_square_mesh_data(std::size_t const max_square_count);
    square_mesh_data make_square_mesh_data(std::size_t const max_square_count, std::size_t const max_index_count);

    class square : public base {
        class impl;

       public:
        explicit square(square_mesh_data);
        square(std::nullptr_t);

        ui::node &node();
        ui::square_mesh_data &square_mesh_data();
    };

    square make_square(std::size_t const max_square_count);
    square make_square(std::size_t const max_square_count, std::size_t const max_index_count);
}
}
