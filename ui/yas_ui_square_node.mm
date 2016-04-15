//
//  yas_ui_square_node.mm
//

#include "yas_each_index.h"
#include "yas_ui_mesh.h"
#include "yas_ui_mesh_data.h"
#include "yas_ui_square_node.h"

using namespace yas;

#pragma mark - square_node::impl

struct ui::square_node::impl : ui::node::impl {
    using super_class = ui::node::impl;

    impl(std::size_t const square_count) : super_class(), _mesh_data(square_count * 4, square_count * 6) {
        _setup_indices(square_count);

        ui::mesh mesh;
        mesh.set_data(_mesh_data);
        set_mesh(std::move(mesh));
    }

    void _setup_indices(std::size_t const square_count) {
        _mesh_data.write([&square_count](auto &, auto &indices) {
            for (auto const &idx : make_each(square_count)) {
                std::size_t const el_top_idx = idx * 6;
                std::size_t const sq_top_idx = idx * 4;

                indices.at(el_top_idx) = sq_top_idx;
                indices.at(el_top_idx + 1) = indices.at(el_top_idx + 4) = sq_top_idx + 2;
                indices.at(el_top_idx + 2) = indices.at(el_top_idx + 3) = sq_top_idx + 1;
                indices.at(el_top_idx + 5) = sq_top_idx + 3;
            }
        });
    }

    void _set_square_index(std::size_t const element_idx, std::size_t const square_idx) {
        _mesh_data.write([&element_idx, &square_idx](auto &, auto &indices) {
            std::size_t const el_top_idx = element_idx * 6;
            std::size_t const sq_top_idx = square_idx * 4;

            indices.at(el_top_idx) = sq_top_idx;
            indices.at(el_top_idx + 1) = indices.at(el_top_idx + 4) = sq_top_idx + 2;
            indices.at(el_top_idx + 2) = indices.at(el_top_idx + 3) = sq_top_idx + 1;
            indices.at(el_top_idx + 5) = sq_top_idx + 3;
        });
    }

    void _set_square_indices(std::vector<std::pair<std::size_t, std::size_t>> const &idx_pairs) {
        for (auto const &idx_pair : idx_pairs) {
            _set_square_index(idx_pair.first, idx_pair.second);
        }
    }

    void _set_square_position(ui::float_region const &region, std::size_t const square_idx,
                              simd::float4x4 const &matrix) {
        _mesh_data.write([&region, &square_idx, &matrix](auto &vertices, auto &) {
            std::size_t const sq_top_idx = square_idx * 4;

            simd::float2 positions[4];
            positions[0].x = positions[2].x = region.origin.x;
            positions[0].y = positions[1].y = region.origin.y;
            positions[1].x = positions[3].x = region.origin.x + region.size.width;
            positions[2].y = positions[3].y = region.origin.y + region.size.height;

            for (auto const &idx : make_each(4)) {
                auto pos = matrix * simd::float4{positions[idx].x, positions[idx].y, 0, 1};
                vertices.at(sq_top_idx + idx).position = simd::float2{pos.x, pos.y};
            }
        });
    }

    void _set_square_tex_coords(ui::uint_region const &pixel_region, std::size_t const square_idx) {
        _mesh_data.write([&pixel_region, &square_idx](auto &vertices, auto &) {
            std::size_t const sq_top_idx = square_idx * 4;
            float min_x = pixel_region.origin.x;
            float min_y = pixel_region.origin.y;
            float max_x = min_x + pixel_region.size.width;
            float max_y = min_y + pixel_region.size.height;

            vertices.at(sq_top_idx).tex_coord[0] = vertices.at(sq_top_idx + 2).tex_coord[0] = min_x;
            vertices.at(sq_top_idx).tex_coord[1] = vertices.at(sq_top_idx + 1).tex_coord[1] = max_y;
            vertices.at(sq_top_idx + 1).tex_coord[0] = vertices.at(sq_top_idx + 3).tex_coord[0] = max_x;
            vertices.at(sq_top_idx + 2).tex_coord[1] = vertices.at(sq_top_idx + 3).tex_coord[1] = min_y;
        });
    }

    void _set_square_vertex(const vertex2d_t *const in_ptr, std::size_t const square_idx,
                            simd::float4x4 const &matrix) {
        _mesh_data.write([&in_ptr, &square_idx, &matrix](auto &vertices, auto &) {
            std::size_t const sq_top_idx = square_idx * 4;

            for (auto const &idx : make_each(4)) {
                auto pos = matrix * simd::float4{in_ptr[idx].position.x, in_ptr[idx].position.y, 0, 1};
                vertices.at(sq_top_idx + idx).position = {pos.x, pos.y};
                vertices.at(sq_top_idx + idx).tex_coord = in_ptr[idx].tex_coord;
            }
        });
    }

    ui::dynamic_mesh_data _mesh_data;
};

#pragma mark - square_node

ui::square_node::square_node(std::size_t const square_count) : super_class(std::make_shared<impl>(square_count)) {
}

ui::square_node::square_node(std::nullptr_t) : super_class(nullptr) {
}

ui::dynamic_mesh_data &ui::square_node::mesh_data() {
    return impl_ptr<impl>()->_mesh_data;
}

void ui::square_node::set_square_index(std::size_t const element_idx, std::size_t const square_idx) {
    impl_ptr<impl>()->_set_square_indices({{element_idx, square_idx}});
}

void ui::square_node::set_square_indices(std::vector<std::pair<std::size_t, std::size_t>> const &idx_pairs) {
    impl_ptr<impl>()->_set_square_indices(idx_pairs);
}

void ui::square_node::set_square_position(ui::float_region const &region, std::size_t const square_idx,
                                          simd::float4x4 const &matrix) {
    impl_ptr<impl>()->_set_square_position(region, square_idx, matrix);
}

void ui::square_node::set_square_tex_coords(ui::uint_region const &pixel_region, std::size_t const square_idx) {
    impl_ptr<impl>()->_set_square_tex_coords(pixel_region, square_idx);
}

void ui::square_node::set_square_vertex(const ui::vertex2d_t *const in_ptr, std::size_t const square_idx,
                                        simd::float4x4 const &matrix) {
    impl_ptr<impl>()->_set_square_vertex(in_ptr, square_idx, matrix);
}
