//
//  yas_ui_rect_plane.h
//

#pragma once

#include <vector>
#include "yas_ui_mesh_data.h"
#include "yas_ui_types.h"

namespace yas {
namespace ui {
    class node;

    struct rect_plane_data {
        explicit rect_plane_data(ui::dynamic_mesh_data mesh_data);

        virtual ~rect_plane_data() final;

        void write(std::function<void(ui::vertex2d_rect_t *, ui::index2d_rect_t *)> const &);
        void write_vertex(std::size_t const rect_idx, std::function<void(ui::vertex2d_rect_t &)> const &);
        void write_index(std::size_t const rect_idx, std::function<void(ui::index2d_rect_t &)> const &);

        std::size_t max_rect_count() const;
        void set_rect_count(std::size_t const);

        void set_rect_index(std::size_t const index_idx, std::size_t const vertex_idx);
        void set_rect_indices(std::vector<std::pair<std::size_t, std::size_t>> const &idx_pairs);
        void set_rect_position(ui::region const &region, std::size_t const rect_idx,
                               simd::float4x4 const &matrix = matrix_identity_float4x4);
        void set_rect_color(simd::float4 const &color, std::size_t const rect_idx);
        void set_rect_tex_coords(ui::uint_region const &pixel_region, std::size_t const rect_idx);
        void set_rect_vertex(const vertex2d_t *const in_ptr, std::size_t const rect_idx,
                             simd::float4x4 const &matrix = matrix_identity_float4x4);

        ui::dynamic_mesh_data &dynamic_mesh_data();

       private:
        ui::dynamic_mesh_data _dynamic_mesh_data;
    };

    rect_plane_data make_rect_plane_data(std::size_t const max_rect_count);
    rect_plane_data make_rect_plane_data(std::size_t const max_rect_count, std::size_t const max_index_count);

    class rect_plane : public base {
        class impl;

       public:
        explicit rect_plane(rect_plane_data);
        rect_plane(std::nullptr_t);

        virtual ~rect_plane() final;

        ui::node &node();
        ui::rect_plane_data &data();
    };

    rect_plane make_rect_plane(std::size_t const max_rect_count);
    rect_plane make_rect_plane(std::size_t const max_rect_count, std::size_t const max_index_count);
}
}
