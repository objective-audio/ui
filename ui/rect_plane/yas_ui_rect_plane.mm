//
//  yas_ui_rect_plane.mm
//

#include "yas_ui_rect_plane.h"
#include <cpp_utils/yas_fast_each.h>
#include "yas_ui_color.h"
#include "yas_ui_mesh.h"
#include "yas_ui_mesh_data.h"
#include "yas_ui_node.h"

using namespace yas;
using namespace yas::ui;

#pragma mark - rect_plane_data

rect_plane_data::rect_plane_data(std::shared_ptr<ui::dynamic_mesh_data> &&mesh_data)
    : _dynamic_mesh_data(std::move(mesh_data)) {
}

rect_plane_data::~rect_plane_data() = default;

std::size_t rect_plane_data::max_rect_count() const {
    auto const max_index_count = this->_dynamic_mesh_data->max_index_count();
    if (max_index_count > 0) {
        return max_index_count / 6;
    }
    return 0;
}

std::size_t rect_plane_data::rect_count() const {
    auto const index_count = this->_dynamic_mesh_data->index_count();
    if (index_count > 0) {
        return index_count / 6;
    }
    return 0;
}

void rect_plane_data::set_rect_count(std::size_t const count) {
    this->dynamic_mesh_data()->set_index_count(count * 6);
}

void rect_plane_data::write(std::function<void(vertex2d_rect_t *, index2d_rect_t *)> const &func) {
    this->dynamic_mesh_data()->write([&func](auto &vertices, auto &indices) {
        func((vertex2d_rect_t *)vertices.data(), (index2d_rect_t *)indices.data());
    });
}

void rect_plane_data::write_vertex(std::size_t const rect_idx, std::function<void(vertex2d_rect_t &)> const &func) {
    this->dynamic_mesh_data()->write([&rect_idx, &func](auto &vertices, auto &indices) {
        auto rect_vertex_ptr = (vertex2d_rect_t *)vertices.data();
        func(rect_vertex_ptr[rect_idx]);
    });
}

void rect_plane_data::write_index(std::size_t const rect_idx, std::function<void(index2d_rect_t &)> const &func) {
    this->dynamic_mesh_data()->write([&rect_idx, &func](auto &vertices, auto &indices) {
        auto rect_index_ptr = (index2d_rect_t *)indices.data();
        func(rect_index_ptr[rect_idx]);
    });
}

void rect_plane_data::set_rect_index(std::size_t const index_idx, std::size_t const vertex_idx) {
    this->write_index(index_idx, [&vertex_idx](auto &rect_idx) {
        auto const rect_top_raw_idx = static_cast<index2d_t>(vertex_idx * 4);

        rect_idx.v[0] = rect_top_raw_idx;
        rect_idx.v[1] = rect_idx.v[4] = rect_top_raw_idx + 2;
        rect_idx.v[2] = rect_idx.v[3] = rect_top_raw_idx + 1;
        rect_idx.v[5] = rect_top_raw_idx + 3;
    });
}

void rect_plane_data::set_rect_indices(std::vector<std::pair<std::size_t, std::size_t>> const &idx_pairs) {
    for (auto const &idx_pair : idx_pairs) {
        this->set_rect_index(idx_pair.first, idx_pair.second);
    }
}

void rect_plane_data::set_rect_position(region const &region, std::size_t const rect_idx,
                                        simd::float4x4 const &matrix) {
    this->write([&region, &rect_idx, &matrix](auto *rect_vertices, auto *) {
        simd::float2 positions[4];
        positions[0].x = positions[2].x = region.origin.x;
        positions[0].y = positions[1].y = region.origin.y;
        positions[1].x = positions[3].x = region.origin.x + region.size.width;
        positions[2].y = positions[3].y = region.origin.y + region.size.height;

        auto &rect_vertex = rect_vertices[rect_idx];
        auto each = make_fast_each(4);
        while (yas_each_next(each)) {
            auto const &idx = yas_each_index(each);
            rect_vertex.v[idx].position = to_float2(matrix * to_float4(positions[idx]));
        }
    });
}

void rect_plane_data::set_rect_color(simd::float4 const &color, std::size_t const rect_idx) {
    this->write([&color, &rect_idx](auto *rect_vertices, auto *) {
        auto &rect_vertex = rect_vertices[rect_idx];
        auto each = make_fast_each(4);
        while (yas_each_next(each)) {
            rect_vertex.v[yas_each_index(each)].color = color;
        }
    });
}

void rect_plane_data::set_rect_color(color const &color, float const alpha, std::size_t const rect_idx) {
    this->set_rect_color(to_float4(color, alpha), rect_idx);
}

void rect_plane_data::set_rect_tex_coords(uint_region const &pixel_region, std::size_t const rect_idx) {
    this->write([&pixel_region, &rect_idx](auto *rect_vertices, auto *) {
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

void rect_plane_data::set_rect_vertex(const vertex2d_t *const in_ptr, std::size_t const rect_idx,
                                      simd::float4x4 const &matrix) {
    this->write([&in_ptr, &rect_idx, &matrix](auto *rect_vertices, auto *) {
        auto &rect_vertex = rect_vertices[rect_idx];
        auto each = make_fast_each(4);
        while (yas_each_next(each)) {
            auto const &idx = yas_each_index(each);
            rect_vertex.v[idx].position = to_float2(matrix * to_float4(in_ptr[idx].position));
            rect_vertex.v[idx].tex_coord = in_ptr[idx].tex_coord;
            rect_vertex.v[idx].color = in_ptr[idx].color;
        }
    });
}

void rect_plane_data::observe_rect_tex_coords(std::shared_ptr<texture_element> const &element,
                                              std::size_t const rect_idx) {
    this->_observe_rect_tex_coords(*this, element, rect_idx, nullptr);
}

void rect_plane_data::observe_rect_tex_coords(std::shared_ptr<texture_element> const &element,
                                              std::size_t const rect_idx, tex_coords_transform_f transformer) {
    this->_observe_rect_tex_coords(*this, element, rect_idx, std::move(transformer));
}

void rect_plane_data::clear_observers() {
    this->_element_cancellers.clear();
}

std::shared_ptr<dynamic_mesh_data> const &rect_plane_data::dynamic_mesh_data() {
    return this->_dynamic_mesh_data;
}

void rect_plane_data::_observe_rect_tex_coords(rect_plane_data &data, std::shared_ptr<texture_element> const &element,
                                               std::size_t const rect_idx, tex_coords_transform_f &&transformer) {
    this->_element_cancellers.emplace_back(
        element
            ->observe_tex_coords([this, rect_idx, transformer = std::move(transformer)](uint_region const &tex_coords) {
                auto transformed = transformer ? transformer(tex_coords) : tex_coords;
                this->set_rect_tex_coords(transformed, rect_idx);
            })
            .sync());
}

std::shared_ptr<rect_plane_data> rect_plane_data::make_shared(std::shared_ptr<ui::dynamic_mesh_data> &&mesh_data) {
    return std::shared_ptr<rect_plane_data>(new rect_plane_data{std::move(mesh_data)});
}

std::shared_ptr<rect_plane_data> rect_plane_data::make_shared(std::size_t const max_rect_count) {
    return make_shared(max_rect_count, max_rect_count);
}

std::shared_ptr<rect_plane_data> rect_plane_data::make_shared(std::size_t const rect_count,
                                                              std::size_t const index_count) {
    auto shared =
        make_shared(dynamic_mesh_data::make_shared({.vertex_count = rect_count * 4, .index_count = index_count * 6}));

    shared->write([&rect_count, &index_count](auto *, auto *rect_indices) {
        auto each = make_fast_each(std::min(rect_count, index_count));
        while (yas_each_next(each)) {
            auto const &idx = yas_each_index(each);
            auto &rect_idx = rect_indices[idx];
            auto const rect_top_raw_idx = static_cast<index2d_t>(idx * 4);
            rect_idx.v[0] = rect_top_raw_idx;
            rect_idx.v[1] = rect_idx.v[4] = rect_top_raw_idx + 2;
            rect_idx.v[2] = rect_idx.v[3] = rect_top_raw_idx + 1;
            rect_idx.v[5] = rect_top_raw_idx + 3;
        }
    });

    return shared;
}

#pragma mark - rect_plane

rect_plane::rect_plane(std::shared_ptr<rect_plane_data> &&plane_data) : _rect_plane_data(std::move(plane_data)) {
    auto mesh = mesh::make_shared();
    mesh->set_mesh_data(this->data()->dynamic_mesh_data());
    this->node()->set_mesh(std::move(mesh));
}

std::shared_ptr<node> const &rect_plane::node() {
    return this->_node;
}

std::shared_ptr<rect_plane_data> const &rect_plane::data() {
    return this->_rect_plane_data;
}

std::shared_ptr<rect_plane> rect_plane::make_shared(std::shared_ptr<rect_plane_data> &&rect_plane_data) {
    return std::shared_ptr<rect_plane>(new rect_plane{std::move(rect_plane_data)});
}

std::shared_ptr<rect_plane> rect_plane::make_shared(std::size_t const rect_count) {
    return make_shared(rect_count, rect_count);
}

std::shared_ptr<rect_plane> rect_plane::make_shared(std::size_t const rect_count, std::size_t const index_count) {
    return make_shared(rect_plane_data::make_shared(rect_count, index_count));
}
