//
//  yas_ui_square_node.mm
//

#include "yas_each_index.h"
#include "yas_ui_mesh.h"
#include "yas_ui_mesh_data.h"
#include "yas_ui_square_node.h"

using namespace yas;

#pragma mark - square_mesh_data

ui::square_mesh_data::square_mesh_data(std::size_t const square_count)
    : _mesh_data(square_count * 4, square_count * 6) {
    write([&square_count](auto *, auto *sq_indices) {
        for (auto const &idx : make_each(square_count)) {
            std::size_t const sq_top_raw_idx = idx * 4;

            auto &sq_index = sq_indices[idx];
            sq_index.v[0] = sq_top_raw_idx;
            sq_index.v[1] = sq_index.v[4] = sq_top_raw_idx + 2;
            sq_index.v[2] = sq_index.v[3] = sq_top_raw_idx + 1;
            sq_index.v[5] = sq_top_raw_idx + 3;
        }
    });
}

void ui::square_mesh_data::set_square_count(std::size_t const count) {
    _mesh_data.set_index_count(count * 6);
}

void ui::square_mesh_data::write(std::function<void(ui::vertex2d_square_t *, ui::index_square_t *)> const &func) {
    _mesh_data.write([&func](auto &vertices, auto &indices) {
        func((vertex2d_square_t *)vertices.data(), (index_square_t *)indices.data());
    });
}

void ui::square_mesh_data::set_square_index(std::size_t const element_idx, std::size_t const square_idx) {
    write([&element_idx, &square_idx](auto *, auto *sq_indices) {
        std::size_t const sq_top_raw_idx = square_idx * 4;

        auto &sq_index = sq_indices[element_idx];
        sq_index.v[0] = sq_top_raw_idx;
        sq_index.v[1] = sq_index.v[4] = sq_top_raw_idx + 2;
        sq_index.v[2] = sq_index.v[3] = sq_top_raw_idx + 1;
        sq_index.v[5] = sq_top_raw_idx + 3;
    });
}

void ui::square_mesh_data::set_square_indices(std::vector<std::pair<std::size_t, std::size_t>> const &idx_pairs) {
    for (auto const &idx_pair : idx_pairs) {
        set_square_index(idx_pair.first, idx_pair.second);
    }
}

void ui::square_mesh_data::set_square_position(ui::float_region const &region, std::size_t const square_idx,
                                               simd::float4x4 const &matrix) {
    write([&region, &square_idx, &matrix](auto *sq_vertices, auto *) {
        simd::float2 positions[4];
        positions[0].x = positions[2].x = region.origin.x;
        positions[0].y = positions[1].y = region.origin.y;
        positions[1].x = positions[3].x = region.origin.x + region.size.width;
        positions[2].y = positions[3].y = region.origin.y + region.size.height;

        auto &sq_vertex = sq_vertices[square_idx];
        for (auto const &idx : make_each(4)) {
            auto pos = matrix * simd::float4{positions[idx].x, positions[idx].y, 0, 1};
            sq_vertex.v[idx].position = simd::float2{pos.x, pos.y};
        }
    });
}

void ui::square_mesh_data::set_square_tex_coords(ui::uint_region const &pixel_region, std::size_t const square_idx) {
    write([&pixel_region, &square_idx](auto *sq_vertices, auto *) {
        float min_x = pixel_region.origin.x;
        float min_y = pixel_region.origin.y;
        float max_x = min_x + pixel_region.size.width;
        float max_y = min_y + pixel_region.size.height;

        auto &sq_vertex = sq_vertices[square_idx];
        sq_vertex.v[0].tex_coord[0] = sq_vertex.v[2].tex_coord[0] = min_x;
        sq_vertex.v[0].tex_coord[1] = sq_vertex.v[1].tex_coord[1] = max_y;
        sq_vertex.v[1].tex_coord[0] = sq_vertex.v[3].tex_coord[0] = max_x;
        sq_vertex.v[2].tex_coord[1] = sq_vertex.v[3].tex_coord[1] = min_y;
    });
}

void ui::square_mesh_data::set_square_vertex(const vertex2d_t *const in_ptr, std::size_t const square_idx,
                                             simd::float4x4 const &matrix) {
    write([&in_ptr, &square_idx, &matrix](auto *sq_vertices, auto *) {
        auto &sq_vertex = sq_vertices[square_idx];
        for (auto const &idx : make_each(4)) {
            auto pos = matrix * simd::float4{in_ptr[idx].position.x, in_ptr[idx].position.y, 0, 1};
            sq_vertex.v[idx].position = {pos.x, pos.y};
            sq_vertex.v[idx].tex_coord = in_ptr[idx].tex_coord;
        }
    });
}

ui::dynamic_mesh_data &ui::square_mesh_data::mesh_data() {
    return _mesh_data;
}

#pragma mark - square_node::impl

struct ui::square_node::impl : ui::node::impl {
    using super_class = ui::node::impl;

    impl(std::size_t const square_count) : super_class(), _mesh_data(square_count) {
        ui::mesh mesh;
        mesh.set_data(_mesh_data.mesh_data());
        set_mesh(std::move(mesh));
    }

    ui::square_mesh_data _mesh_data;
};

#pragma mark - square_node

ui::square_node::square_node(std::size_t const square_count) : super_class(std::make_shared<impl>(square_count)) {
}

ui::square_node::square_node(std::nullptr_t) : super_class(nullptr) {
}

ui::square_mesh_data &ui::square_node::square_mesh_data() {
    return impl_ptr<impl>()->_mesh_data;
}
