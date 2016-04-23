//
//  yas_ui_square_node.mm
//

#include "yas_each_index.h"
#include "yas_ui_mesh.h"
#include "yas_ui_mesh_data.h"
#include "yas_ui_node.h"
#include "yas_ui_square_node.h"

using namespace yas;

#pragma mark - square_mesh_data

ui::square_mesh_data::square_mesh_data(ui::dynamic_mesh_data mesh_data) : _dynamic_mesh_data(std::move(mesh_data)) {
}

std::size_t ui::square_mesh_data::max_square_count() const {
    auto const max_index_count = _dynamic_mesh_data.max_index_count();
    if (max_index_count > 0) {
        return max_index_count / 6;
    }
    return 0;
}

void ui::square_mesh_data::set_square_count(std::size_t const count) {
    _dynamic_mesh_data.set_index_count(count * 6);
}

void ui::square_mesh_data::write(std::size_t const square_idx,
                                 std::function<void(ui::vertex2d_square_t &, ui::index_square_t &)> const &func) {
    _dynamic_mesh_data.write([&square_idx, &func](auto &vertices, auto &indices) {
        auto sq_vertex_ptr = (vertex2d_square_t *)vertices.data();
        auto sq_index_ptr = (index_square_t *)indices.data();
        func(sq_vertex_ptr[square_idx], sq_index_ptr[square_idx]);
    });
}

void ui::square_mesh_data::write(std::function<void(ui::vertex2d_square_t *, ui::index_square_t *)> const &func) {
    _dynamic_mesh_data.write([&func](auto &vertices, auto &indices) {
        func((vertex2d_square_t *)vertices.data(), (index_square_t *)indices.data());
    });
}

void ui::square_mesh_data::set_square_index(std::size_t const index_idx, std::size_t const vertex_idx) {
    write(index_idx, [&vertex_idx](auto &, auto &sq_index) {
        std::size_t const sq_top_raw_idx = vertex_idx * 4;

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
        float const min_x = pixel_region.origin.x;
        float const min_y = pixel_region.origin.y;
        float const max_x = min_x + pixel_region.size.width;
        float const max_y = min_y + pixel_region.size.height;

        auto &sq_vertex = sq_vertices[square_idx];
        sq_vertex.v[0].tex_coord.x = sq_vertex.v[2].tex_coord.x = min_x;
        sq_vertex.v[0].tex_coord.y = sq_vertex.v[1].tex_coord.y = max_y;
        sq_vertex.v[1].tex_coord.x = sq_vertex.v[3].tex_coord.x = max_x;
        sq_vertex.v[2].tex_coord.y = sq_vertex.v[3].tex_coord.y = min_y;
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

ui::dynamic_mesh_data &ui::square_mesh_data::dynamic_mesh_data() {
    return _dynamic_mesh_data;
}

ui::square_mesh_data ui::make_square_mesh_data(std::size_t const square_count) {
    ui::square_mesh_data sq_mesh_data{ui::dynamic_mesh_data{square_count * 4, square_count * 6}};

    sq_mesh_data.write([&square_count](auto *, auto *sq_indices) {
        for (auto const &idx : make_each(square_count)) {
            auto &sq_index = sq_indices[idx];
            std::size_t const sq_top_raw_idx = idx * 4;
            sq_index.v[0] = sq_top_raw_idx;
            sq_index.v[1] = sq_index.v[4] = sq_top_raw_idx + 2;
            sq_index.v[2] = sq_index.v[3] = sq_top_raw_idx + 1;
            sq_index.v[5] = sq_top_raw_idx + 3;
        }
    });

    return sq_mesh_data;
}

#pragma mark - ui::square_node::impl

struct yas::ui::square_node::impl : base::impl {
    impl(ui::square_mesh_data &&sq_mesh_data) : _square_mesh_data(std::move(sq_mesh_data)) {
    }

    ui::node _node;
    ui::square_mesh_data _square_mesh_data;
};

#pragma mark - ui::square_node

ui::square_node::square_node(ui::square_mesh_data sq_mesh_data)
    : base(std::make_shared<impl>(std::move(sq_mesh_data))) {
}

ui::square_node::square_node(std::nullptr_t) : base(nullptr) {
}

ui::node &ui::square_node::node() {
    return impl_ptr<impl>()->_node;
}

ui::square_mesh_data &ui::square_node::square_mesh_data() {
    return impl_ptr<impl>()->_square_mesh_data;
}

ui::square_node ui::make_square_node(std::size_t const square_count) {
    ui::square_node node{make_square_mesh_data(square_count)};
    ui::mesh mesh;
    mesh.set_mesh_data(node.square_mesh_data().dynamic_mesh_data());
    node.node().set_mesh(std::move(mesh));

    return node;
}
