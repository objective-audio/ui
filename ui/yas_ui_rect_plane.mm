//
//  yas_ui_rect_plane.mm
//

#include "yas_each_index.h"
#include "yas_ui_mesh.h"
#include "yas_ui_mesh_data.h"
#include "yas_ui_node.h"
#include "yas_ui_rect_plane.h"

using namespace yas;

#pragma mark - rect_plane_data

ui::rect_plane_data::rect_plane_data(ui::dynamic_mesh_data mesh_data) : _dynamic_mesh_data(std::move(mesh_data)) {
}

std::size_t ui::rect_plane_data::max_rect_count() const {
    auto const max_index_count = _dynamic_mesh_data.max_index_count();
    if (max_index_count > 0) {
        return max_index_count / 6;
    }
    return 0;
}

void ui::rect_plane_data::set_rect_count(std::size_t const count) {
    _dynamic_mesh_data.set_index_count(count * 6);
}

void ui::rect_plane_data::write(std::function<void(ui::vertex2d_rect_t *, ui::index2d_rect_t *)> const &func) {
    _dynamic_mesh_data.write([&func](auto &vertices, auto &indices) {
        func((vertex2d_rect_t *)vertices.data(), (index2d_rect_t *)indices.data());
    });
}

void ui::rect_plane_data::write_vertex(std::size_t const rect_idx,
                                       std::function<void(ui::vertex2d_rect_t &)> const &func) {
    _dynamic_mesh_data.write([&rect_idx, &func](auto &vertices, auto &indices) {
        auto rect_vertex_ptr = (vertex2d_rect_t *)vertices.data();
        func(rect_vertex_ptr[rect_idx]);
    });
}

void ui::rect_plane_data::write_index(std::size_t const rect_idx,
                                      std::function<void(ui::index2d_rect_t &)> const &func) {
    _dynamic_mesh_data.write([&rect_idx, &func](auto &vertices, auto &indices) {
        auto rect_index_ptr = (index2d_rect_t *)indices.data();
        func(rect_index_ptr[rect_idx]);
    });
}

void ui::rect_plane_data::set_rect_index(std::size_t const index_idx, std::size_t const vertex_idx) {
    write_index(index_idx, [&vertex_idx](auto &rect_idx) {
        auto const rect_top_raw_idx = static_cast<index2d_t>(vertex_idx * 4);

        rect_idx.v[0] = rect_top_raw_idx;
        rect_idx.v[1] = rect_idx.v[4] = rect_top_raw_idx + 2;
        rect_idx.v[2] = rect_idx.v[3] = rect_top_raw_idx + 1;
        rect_idx.v[5] = rect_top_raw_idx + 3;
    });
}

void ui::rect_plane_data::set_rect_indices(std::vector<std::pair<std::size_t, std::size_t>> const &idx_pairs) {
    for (auto const &idx_pair : idx_pairs) {
        set_rect_index(idx_pair.first, idx_pair.second);
    }
}

void ui::rect_plane_data::set_rect_position(ui::float_region const &region, std::size_t const rect_idx,
                                            simd::float4x4 const &matrix) {
    write([&region, &rect_idx, &matrix](auto *rect_vertices, auto *) {
        simd::float2 positions[4];
        positions[0].x = positions[2].x = region.origin.x;
        positions[0].y = positions[1].y = region.origin.y;
        positions[1].x = positions[3].x = region.origin.x + region.size.width;
        positions[2].y = positions[3].y = region.origin.y + region.size.height;

        auto &rect_vertex = rect_vertices[rect_idx];
        for (auto const &idx : make_each(4)) {
            rect_vertex.v[idx].position = to_float2(matrix * to_float4(positions[idx]));
        }
    });
}

void ui::rect_plane_data::set_rect_color(simd::float4 const &color, std::size_t const rect_idx) {
    write([&color, &rect_idx](auto *rect_vertices, auto *) {
        auto &rect_vertex = rect_vertices[rect_idx];
        for (auto const &idx : make_each(4)) {
            rect_vertex.v[idx].color = color;
        }
    });
}

void ui::rect_plane_data::set_rect_tex_coords(ui::uint_region const &pixel_region, std::size_t const rect_idx) {
    write([&pixel_region, &rect_idx](auto *rect_vertices, auto *) {
        float const min_x = pixel_region.origin.x;
        float const min_y = pixel_region.origin.y;
        float const max_x = min_x + pixel_region.size.width;
        float const max_y = min_y + pixel_region.size.height;

        auto &rect_vertex = rect_vertices[rect_idx];
        rect_vertex.v[0].tex_coord.x = rect_vertex.v[2].tex_coord.x = min_x;
        rect_vertex.v[0].tex_coord.y = rect_vertex.v[1].tex_coord.y = max_y;
        rect_vertex.v[1].tex_coord.x = rect_vertex.v[3].tex_coord.x = max_x;
        rect_vertex.v[2].tex_coord.y = rect_vertex.v[3].tex_coord.y = min_y;
    });
}

void ui::rect_plane_data::set_rect_vertex(const vertex2d_t *const in_ptr, std::size_t const rect_idx,
                                          simd::float4x4 const &matrix) {
    write([&in_ptr, &rect_idx, &matrix](auto *rect_vertices, auto *) {
        auto &rect_vertex = rect_vertices[rect_idx];
        for (auto const &idx : make_each(4)) {
            rect_vertex.v[idx].position = to_float2(matrix * to_float4(in_ptr[idx].position));
            rect_vertex.v[idx].tex_coord = in_ptr[idx].tex_coord;
            rect_vertex.v[idx].color = in_ptr[idx].color;
        }
    });
}

ui::dynamic_mesh_data &ui::rect_plane_data::dynamic_mesh_data() {
    return _dynamic_mesh_data;
}

ui::rect_plane_data ui::make_rect_plane_data(std::size_t const rect_count) {
    ui::rect_plane_data plane_data{
        ui::dynamic_mesh_data{{.vertex_count = rect_count * 4, .index_count = rect_count * 6}}};

    plane_data.write([&rect_count](auto *, auto *rect_indices) {
        for (auto const &idx : make_each(rect_count)) {
            auto &rect_idx = rect_indices[idx];
            auto const rect_top_raw_idx = static_cast<index2d_t>(idx * 4);
            rect_idx.v[0] = rect_top_raw_idx;
            rect_idx.v[1] = rect_idx.v[4] = rect_top_raw_idx + 2;
            rect_idx.v[2] = rect_idx.v[3] = rect_top_raw_idx + 1;
            rect_idx.v[5] = rect_top_raw_idx + 3;
        }
    });

    return plane_data;
}

ui::rect_plane_data ui::make_rect_plane_data(std::size_t const rect_count, std::size_t const index_count) {
    ui::rect_plane_data plane_data{
        ui::dynamic_mesh_data{{.vertex_count = rect_count * 4, .index_count = index_count * 6}}};

    plane_data.write([&rect_count, &index_count](auto *, auto *rect_indices) {
        for (auto const &idx : make_each(std::min(rect_count, index_count))) {
            auto &rect_idx = rect_indices[idx];
            auto const rect_top_raw_idx = static_cast<index2d_t>(idx * 4);
            rect_idx.v[0] = rect_top_raw_idx;
            rect_idx.v[1] = rect_idx.v[4] = rect_top_raw_idx + 2;
            rect_idx.v[2] = rect_idx.v[3] = rect_top_raw_idx + 1;
            rect_idx.v[5] = rect_top_raw_idx + 3;
        }
    });

    return plane_data;
}

#pragma mark - ui::rect_plane::impl

struct yas::ui::rect_plane::impl : base::impl {
    impl(ui::rect_plane_data &&plane_data) : _rect_plane_data(std::move(plane_data)) {
    }

    ui::node _node;
    ui::rect_plane_data _rect_plane_data;
};

#pragma mark - ui::rect_plane

ui::rect_plane::rect_plane(ui::rect_plane_data rect_plane_data)
    : base(std::make_shared<impl>(std::move(rect_plane_data))) {
}

ui::rect_plane::rect_plane(std::nullptr_t) : base(nullptr) {
}

ui::node &ui::rect_plane::node() {
    return impl_ptr<impl>()->_node;
}

ui::rect_plane_data &ui::rect_plane::data() {
    return impl_ptr<impl>()->_rect_plane_data;
}

ui::rect_plane ui::make_rect_plane(std::size_t const rect_count) {
    return make_rect_plane(rect_count, rect_count);
}

ui::rect_plane ui::make_rect_plane(std::size_t const rect_count, std::size_t const index_count) {
    ui::rect_plane node{make_rect_plane_data(rect_count, index_count)};
    ui::mesh mesh;
    mesh.set_mesh_data(node.data().dynamic_mesh_data());
    node.node().set_mesh(std::move(mesh));

    return node;
}
