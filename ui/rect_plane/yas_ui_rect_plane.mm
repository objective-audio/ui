//
//  yas_ui_rect_plane.mm
//

#include "yas_ui_rect_plane.h"
#include <cpp_utils/yas_fast_each.h>
#include <ui/yas_ui_dynamic_mesh_data.h>
#include <ui/yas_ui_mesh.h>
#include <ui/yas_ui_node.h>
#include <ui/yas_ui_rgb_color.h>

using namespace yas;
using namespace yas::ui;

#pragma mark - rect_plane_data

rect_plane_data::rect_plane_data(std::shared_ptr<ui::dynamic_mesh_vertex_data> &&vertex_data,
                                 std::shared_ptr<ui::dynamic_mesh_index_data> &&index_data)
    : _vertex_data(std::move(vertex_data)), _index_data(std::move(index_data)) {
}

std::size_t rect_plane_data::max_rect_count() const {
    auto const max_index_count = this->_index_data->max_count();
    if (max_index_count > 0) {
        return max_index_count / 6;
    }
    return 0;
}

std::size_t rect_plane_data::rect_count() const {
    auto const index_count = this->_index_data->count();
    if (index_count > 0) {
        return index_count / 6;
    }
    return 0;
}

void rect_plane_data::set_rect_count(std::size_t const count) {
    this->_index_data->set_count(count * 6);
}

void rect_plane_data::write_vertices(std::function<void(vertex2d_rect *)> const &handler) {
    this->_vertex_data->write(
        [&handler](std::vector<vertex2d_t> &vertices) { handler((vertex2d_rect *)vertices.data()); });
}

void rect_plane_data::write_indices(std::function<void(ui::index2d_rect *)> const &handler) {
    this->_index_data->write([&handler](std::vector<index2d_t> &indices) { handler((index2d_rect *)indices.data()); });
}

void rect_plane_data::set_rect_index(std::size_t const index_idx, std::size_t const vertex_idx) {
    this->write_indices([&index_idx, &vertex_idx](ui::index2d_rect *index_rects) {
        auto const rect_head_vertex_raw_idx = static_cast<index2d_t>(vertex_idx * 4);
        index_rects[index_idx].set_all(rect_head_vertex_raw_idx);
    });
}

void rect_plane_data::set_rect_indices(std::vector<std::pair<std::size_t, std::size_t>> const &idx_pairs) {
    for (auto const &idx_pair : idx_pairs) {
        this->set_rect_index(idx_pair.first, idx_pair.second);
    }
}

void rect_plane_data::set_rect_position(region const &region, std::size_t const rect_idx,
                                        simd::float4x4 const &matrix) {
    this->write_vertices([&rect_idx, &region, &matrix](vertex2d_rect *vertex_rects) {
        auto const positions = region.positions(matrix);

        auto each = make_fast_each(4);
        while (yas_each_next(each)) {
            auto const &idx = yas_each_index(each);
            vertex_rects[rect_idx].v[idx].position = positions.v[idx];
        }
    });
}

void rect_plane_data::set_rect_color(simd::float4 const &color, std::size_t const rect_idx) {
    this->write_vertices([&rect_idx, &color](vertex2d_rect *vertex_rects) {
        vertex_rects[rect_idx].set_color(color);
    });
}

void rect_plane_data::set_rect_color(ui::color const &color, std::size_t const rect_idx) {
    this->set_rect_color(color.v, rect_idx);
}

void rect_plane_data::set_rect_color(rgb_color const &color, float const alpha, std::size_t const rect_idx) {
    this->set_rect_color(to_float4(color, alpha), rect_idx);
}

void rect_plane_data::set_rect_tex_coords(uint_region const &pixel_region, std::size_t const rect_idx) {
    this->write_vertices([&rect_idx, &pixel_region](vertex2d_rect *vertex_rects) {
        auto const positions = pixel_region.positions();
        auto each = make_fast_each(4);
        while (yas_each_next(each)) {
            auto const &idx = yas_each_index(each);
            vertex_rects[rect_idx].v[idx].tex_coord = positions.v[idx];
        }
    });
}

void rect_plane_data::set_rect_vertex(const vertex2d_t *const in_ptr, std::size_t const rect_idx,
                                      simd::float4x4 const &matrix) {
    this->write_vertices([&rect_idx, &in_ptr, &matrix](vertex2d_rect *vertex_rects) {
        auto &vertex_rect = vertex_rects[rect_idx];
        auto each = make_fast_each(4);
        while (yas_each_next(each)) {
            auto const &idx = yas_each_index(each);
            auto &array = vertex_rect.v[idx];
            array.position = to_float2(matrix * to_float4(in_ptr[idx].position));
            array.tex_coord = in_ptr[idx].tex_coord;
            array.color = in_ptr[idx].color;
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

std::shared_ptr<dynamic_mesh_vertex_data> const &rect_plane_data::dynamic_vertex_data() {
    return this->_vertex_data;
}

std::shared_ptr<dynamic_mesh_index_data> const &rect_plane_data::dynamic_index_data() {
    return this->_index_data;
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

std::shared_ptr<rect_plane_data> rect_plane_data::make_shared(
    std::shared_ptr<ui::dynamic_mesh_vertex_data> &&vertex_data,
    std::shared_ptr<ui::dynamic_mesh_index_data> &&index_data) {
    return std::shared_ptr<rect_plane_data>(new rect_plane_data{std::move(vertex_data), std::move(index_data)});
}

std::shared_ptr<rect_plane_data> rect_plane_data::make_shared(std::size_t const max_rect_count) {
    return make_shared(max_rect_count, max_rect_count);
}

std::shared_ptr<rect_plane_data> rect_plane_data::make_shared(std::size_t const rect_count,
                                                              std::size_t const index_count) {
    auto shared = make_shared(dynamic_mesh_vertex_data::make_shared(rect_count * 4),
                              dynamic_mesh_index_data::make_shared(rect_count * 6));

    shared->write_indices([&rect_count, &index_count](index2d_rect *index_rects) {
        auto each = make_fast_each(std::min(rect_count, index_count));
        while (yas_each_next(each)) {
            auto const &idx = yas_each_index(each);
            auto &index_rect = index_rects[idx];
            auto const rect_head_vertex_raw_idx = static_cast<index2d_t>(idx * 4);
            index_rect.set_all(rect_head_vertex_raw_idx);
        }
    });

    return shared;
}

#pragma mark - rect_plane

rect_plane::rect_plane(std::shared_ptr<rect_plane_data> &&plane_data) : _rect_plane_data(std::move(plane_data)) {
    auto const mesh = mesh::make_shared({}, this->_rect_plane_data->dynamic_vertex_data(),
                                        this->_rect_plane_data->dynamic_index_data(), nullptr);
    this->node()->set_mesh(mesh);
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

std::shared_ptr<rect_plane> rect_plane::make_shared(std::shared_ptr<rect_plane_data> const &rect_plane_data) {
    auto copied_data = rect_plane_data;
    return std::shared_ptr<rect_plane>(new rect_plane{std::move(copied_data)});
}

std::shared_ptr<rect_plane> rect_plane::make_shared(std::size_t const rect_count) {
    return make_shared(rect_count, rect_count);
}

std::shared_ptr<rect_plane> rect_plane::make_shared(std::size_t const rect_count, std::size_t const index_count) {
    return make_shared(rect_plane_data::make_shared(rect_count, index_count));
}
