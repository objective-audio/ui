//
//  yas_ui_rect_plane.mm
//

#include "yas_ui_mesh.h"
#include "yas_ui_mesh_data.h"
#include "yas_ui_node.h"
#include "yas_ui_rect_plane.h"
#include "yas_ui_color.h"
#include "yas_fast_each.h"

using namespace yas;

#pragma mark - rect_plane_data::impl

struct ui::rect_plane_data::impl : base::impl {
    ui::dynamic_mesh_data _dynamic_mesh_data;
    std::vector<ui::texture_element::observer_t> _element_observers;

    impl(ui::dynamic_mesh_data &&data) : _dynamic_mesh_data(std::move(data)) {
    }

    void observe_rect_tex_coords(ui::rect_plane_data &data, ui::texture_element &element, std::size_t const rect_idx) {
        this->_element_observers.emplace_back(
            element.subject().make_observer(ui::texture_element::method::tex_coords_changed,
                                            [weak_data = to_weak(data), rect_idx](auto const &context) {
                                                if (auto data = weak_data.lock()) {
                                                    ui::texture_element const &element = context.value;
                                                    data.set_rect_tex_coords(element.tex_coords(), rect_idx);
                                                }
                                            }));

        data.set_rect_tex_coords(element.tex_coords(), rect_idx);
    }

    void observe_rect_tex_coords(ui::rect_plane_data &data, ui::texture_element &element, std::size_t const rect_idx,
                                 tex_coords_transform_f &&transformer) {
        if (!transformer) {
            throw std::invalid_argument("tex_coords transformer is null.");
        }

        this->_element_observers.emplace_back(element.subject().make_observer(
            ui::texture_element::method::tex_coords_changed,
            [weak_data = to_weak(data), transformer = std::move(transformer), rect_idx](auto const &context) {
                if (auto data = weak_data.lock()) {
                    ui::texture_element const &element = context.value;
                    data.set_rect_tex_coords(transformer(element.tex_coords()), rect_idx);
                }
            }));

        data.set_rect_tex_coords(transformer(element.tex_coords()), rect_idx);
    }
};

#pragma mark - rect_plane_data

ui::rect_plane_data::rect_plane_data(ui::dynamic_mesh_data mesh_data)
    : base(std::make_shared<impl>(std::move(mesh_data))) {
}

ui::rect_plane_data::rect_plane_data(std::size_t const rect_count) : rect_plane_data(rect_count, rect_count) {
}

ui::rect_plane_data::rect_plane_data(std::size_t const rect_count, std::size_t index_count)
    : rect_plane_data(ui::dynamic_mesh_data{{.vertex_count = rect_count * 4, .index_count = index_count * 6}}) {
    this->write([&rect_count, &index_count](auto *, auto *rect_indices) {
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
}

ui::rect_plane_data::rect_plane_data(std::nullptr_t) : base(nullptr) {
}

ui::rect_plane_data::~rect_plane_data() = default;

std::size_t ui::rect_plane_data::max_rect_count() const {
    auto const max_index_count = impl_ptr<impl>()->_dynamic_mesh_data.max_index_count();
    if (max_index_count > 0) {
        return max_index_count / 6;
    }
    return 0;
}

std::size_t ui::rect_plane_data::rect_count() const {
    auto const index_count = impl_ptr<impl>()->_dynamic_mesh_data.index_count();
    if (index_count > 0) {
        return index_count / 6;
    }
    return 0;
}

void ui::rect_plane_data::set_rect_count(std::size_t const count) {
    this->dynamic_mesh_data().set_index_count(count * 6);
}

void ui::rect_plane_data::write(std::function<void(ui::vertex2d_rect_t *, ui::index2d_rect_t *)> const &func) {
    this->dynamic_mesh_data().write([&func](auto &vertices, auto &indices) {
        func((vertex2d_rect_t *)vertices.data(), (index2d_rect_t *)indices.data());
    });
}

void ui::rect_plane_data::write_vertex(std::size_t const rect_idx,
                                       std::function<void(ui::vertex2d_rect_t &)> const &func) {
    this->dynamic_mesh_data().write([&rect_idx, &func](auto &vertices, auto &indices) {
        auto rect_vertex_ptr = (vertex2d_rect_t *)vertices.data();
        func(rect_vertex_ptr[rect_idx]);
    });
}

void ui::rect_plane_data::write_index(std::size_t const rect_idx,
                                      std::function<void(ui::index2d_rect_t &)> const &func) {
    this->dynamic_mesh_data().write([&rect_idx, &func](auto &vertices, auto &indices) {
        auto rect_index_ptr = (index2d_rect_t *)indices.data();
        func(rect_index_ptr[rect_idx]);
    });
}

void ui::rect_plane_data::set_rect_index(std::size_t const index_idx, std::size_t const vertex_idx) {
    this->write_index(index_idx, [&vertex_idx](auto &rect_idx) {
        auto const rect_top_raw_idx = static_cast<index2d_t>(vertex_idx * 4);

        rect_idx.v[0] = rect_top_raw_idx;
        rect_idx.v[1] = rect_idx.v[4] = rect_top_raw_idx + 2;
        rect_idx.v[2] = rect_idx.v[3] = rect_top_raw_idx + 1;
        rect_idx.v[5] = rect_top_raw_idx + 3;
    });
}

void ui::rect_plane_data::set_rect_indices(std::vector<std::pair<std::size_t, std::size_t>> const &idx_pairs) {
    for (auto const &idx_pair : idx_pairs) {
        this->set_rect_index(idx_pair.first, idx_pair.second);
    }
}

void ui::rect_plane_data::set_rect_position(ui::region const &region, std::size_t const rect_idx,
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

void ui::rect_plane_data::set_rect_color(simd::float4 const &color, std::size_t const rect_idx) {
    this->write([&color, &rect_idx](auto *rect_vertices, auto *) {
        auto &rect_vertex = rect_vertices[rect_idx];
        auto each = make_fast_each(4);
        while (yas_each_next(each)) {
            rect_vertex.v[yas_each_index(each)].color = color;
        }
    });
}

void ui::rect_plane_data::set_rect_color(ui::color const &color, float const alpha, std::size_t const rect_idx) {
    this->set_rect_color(to_float4(color, alpha), rect_idx);
}

void ui::rect_plane_data::set_rect_tex_coords(ui::uint_region const &pixel_region, std::size_t const rect_idx) {
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

void ui::rect_plane_data::set_rect_vertex(const vertex2d_t *const in_ptr, std::size_t const rect_idx,
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

void ui::rect_plane_data::observe_rect_tex_coords(ui::texture_element &element, std::size_t const rect_idx) {
    impl_ptr<impl>()->observe_rect_tex_coords(*this, element, rect_idx);
}

void ui::rect_plane_data::observe_rect_tex_coords(ui::texture_element &element, std::size_t const rect_idx,
                                                  tex_coords_transform_f transformer) {
    impl_ptr<impl>()->observe_rect_tex_coords(*this, element, rect_idx, std::move(transformer));
}

void ui::rect_plane_data::clear_observers() {
    impl_ptr<impl>()->_element_observers.clear();
}

ui::dynamic_mesh_data &ui::rect_plane_data::dynamic_mesh_data() {
    return impl_ptr<impl>()->_dynamic_mesh_data;
}

ui::rect_plane_data ui::make_rect_plane_data(std::size_t const rect_count) {
    return ui::rect_plane_data{rect_count, rect_count};
}

ui::rect_plane_data ui::make_rect_plane_data(std::size_t const rect_count, std::size_t const index_count) {
    return ui::rect_plane_data{rect_count, index_count};
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
    ui::mesh mesh;
    mesh.set_mesh_data(this->data().dynamic_mesh_data());
    this->node().set_mesh(std::move(mesh));
}

ui::rect_plane::rect_plane(std::size_t const rect_count) : rect_plane(rect_count, rect_count) {
}

ui::rect_plane::rect_plane(std::size_t const rect_count, std::size_t const index_count)
    : rect_plane(ui::rect_plane_data{rect_count, index_count}) {
}

ui::rect_plane::rect_plane(std::nullptr_t) : base(nullptr) {
}

ui::rect_plane::~rect_plane() = default;

ui::node &ui::rect_plane::node() {
    return impl_ptr<impl>()->_node;
}

ui::rect_plane_data &ui::rect_plane::data() {
    return impl_ptr<impl>()->_rect_plane_data;
}

ui::rect_plane ui::make_rect_plane(std::size_t const rect_count) {
    return ui::rect_plane(rect_count);
}

ui::rect_plane ui::make_rect_plane(std::size_t const rect_count, std::size_t const index_count) {
    return ui::rect_plane(rect_count, index_count);
}
