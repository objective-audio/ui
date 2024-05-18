//
//  yas_ui_mesh.mm
//

#include "yas_ui_mesh.h"

#include <cpp-utils/fast_each.h>
#include <cpp-utils/objc_ptr.h>
#include <cpp-utils/unless.h>
#include <ui/batch/yas_ui_batch_render_mesh_info.h>
#include <ui/mesh_data/yas_ui_dynamic_mesh_data.h>
#include <ui/metal/yas_ui_metal_encode_info.h>
#include <ui/metal/yas_ui_metal_system.h>
#include <ui/metal/yas_ui_metal_types.h>
#include <ui/renderer/yas_ui_renderer.h>
#include <ui/texture/yas_ui_texture.h>

using namespace yas;
using namespace yas::ui;

#pragma mark - mesh

mesh::mesh(mesh_args &&args, std::shared_ptr<mesh_vertex_data> const &vertex_data,
           std::shared_ptr<mesh_index_data> const &index_data, std::shared_ptr<ui::texture> const &texture)
    : _vertex_data(vertex_data),
      _index_data(index_data),
      _texture(texture),
      _primitive_type(args.primitive_type),
      _color(args.color),
      _use_mesh_color(args.use_mesh_color) {
    this->_updates.flags.set();
}

std::shared_ptr<mesh_vertex_data> const &mesh::vertex_data() const {
    return this->_vertex_data;
}

std::shared_ptr<mesh_index_data> const &mesh::index_data() const {
    return this->_index_data;
}

std::shared_ptr<texture> const &mesh::texture() const {
    return this->_texture;
}

ui::color const &mesh::color() const {
    return this->_color;
}

bool mesh::is_use_mesh_color() const {
    return this->_use_mesh_color;
}

primitive_type const &mesh::primitive_type() const {
    return this->_primitive_type;
}

void mesh::set_vertex_data(std::shared_ptr<mesh_vertex_data> const &data) {
    if (this->_vertex_data != data) {
        this->_vertex_data = data;

        this->_updates.set(mesh_update_reason::vertex_data);
    }
}

void mesh::set_index_data(std::shared_ptr<mesh_index_data> const &data) {
    if (this->_index_data != data) {
        this->_index_data = data;

        this->_updates.set(mesh_update_reason::index_data);
    }
}

void mesh::set_texture(std::shared_ptr<ui::texture> const &texture) {
    if (this->_texture != texture) {
        this->_texture = texture;

        if (this->_is_mesh_data_exists()) {
            this->_updates.set(mesh_update_reason::texture);
        }
    }
}

void mesh::set_color(ui::color const &color) {
    if (this->_color != color) {
        this->_color = color;

        if (this->_is_mesh_data_exists() && !this->_use_mesh_color) {
            this->_updates.set(mesh_update_reason::color);
        }
    }
}

void mesh::set_use_mesh_color(bool const use) {
    if (this->_use_mesh_color != use) {
        this->_use_mesh_color = use;

        if (this->_is_mesh_data_exists()) {
            this->_updates.set(mesh_update_reason::use_mesh_color);
        }
    }
}

void mesh::set_primitive_type(ui::primitive_type const type) {
    if (this->_primitive_type != type) {
        this->_primitive_type = type;

        if (this->_is_mesh_data_exists()) {
            this->_updates.set(mesh_update_reason::primitive_type);
        }
    }
}

simd::float4x4 const &mesh::matrix() {
    return this->_matrix;
}

void mesh::set_matrix(simd::float4x4 const &matrix) {
    if (this->_matrix != matrix) {
        this->_matrix = matrix;

        if (this->is_rendering_color_exists()) {
            this->_updates.set(mesh_update_reason::matrix);
        }
    }
}

std::size_t mesh::render_vertex_count() {
    if (this->is_rendering_color_exists()) {
        if (this->_vertex_data && this->_index_data) {
            return this->_vertex_data->count();
        }
    }
    return 0;
}

std::size_t mesh::render_index_count() {
    if (this->is_rendering_color_exists()) {
        if (this->_vertex_data && this->_index_data) {
            return this->_index_data->count();
        }
    }
    return 0;
}

mesh_updates_t const &mesh::updates() {
    return this->_updates;
}

bool mesh::pre_render() {
    if (this->_vertex_data && this->_index_data) {
        this->_vertex_data->update_render_buffer();
        this->_index_data->update_render_buffer();
        return this->is_rendering_color_exists();
    }

    return false;
}

void mesh::batch_render(batch_render_mesh_info &mesh_info, batch_building_type const building_type) {
    auto const next_vertex_idx = mesh_info.vertex_idx + this->_vertex_data->count();
    auto const next_index_idx = mesh_info.index_idx + this->_index_data->count();

    assert(next_vertex_idx <= mesh_info.vertex_count);
    assert(next_index_idx <= mesh_info.index_count);

    if (this->_needs_write(building_type)) {
        mesh_info.vertex_data->write([&src_vertex_data = this->_vertex_data, &matrix = this->_matrix,
                                      &color = this->_color, is_use_mesh_color = this->_use_mesh_color,
                                      &mesh_info](auto &vertices) {
            auto const dst_vertex_offset = static_cast<index2d_t>(mesh_info.vertex_idx);

            auto *dst_vertices = &vertices[dst_vertex_offset];
            auto const *src_vertices = src_vertex_data->raw_data();

            auto each = make_fast_each(src_vertex_data->count());
            while (yas_each_next(each)) {
                auto &idx = yas_each_index(each);
                auto &dst_vertex = dst_vertices[idx];
                auto &src_vertex = src_vertices[idx];
                dst_vertex.position = to_float2(matrix * to_float4(src_vertex.position));
                dst_vertex.tex_coord = src_vertex.tex_coord;
                dst_vertex.color = is_use_mesh_color ? src_vertex.color * color.v : color.v;
            }
        });

        mesh_info.index_data->write([&src_index_data = this->_index_data, &mesh_info](auto &indices) {
            auto const dst_index_offset = static_cast<index2d_t>(mesh_info.index_idx);
            auto const dst_vertex_offset = static_cast<index2d_t>(mesh_info.vertex_idx);

            auto *dst_indices = &indices[dst_index_offset];
            auto const *src_indices = src_index_data->raw_data();

            auto each = make_fast_each(src_index_data->count());
            while (yas_each_next(each)) {
                auto const &idx = yas_each_index(each);
                dst_indices[idx] = src_indices[idx] + dst_vertex_offset;
            }
        });
    }

    mesh_info.vertex_idx = next_vertex_idx;
    mesh_info.index_idx = next_index_idx;
}

bool mesh::is_rendering_color_exists() {
    return this->_is_mesh_data_exists();
}

void mesh::clear_updates() {
    this->_updates.flags.reset();

    if (this->_vertex_data) {
        this->_vertex_data->clear_updates();
    }

    if (this->_index_data) {
        this->_index_data->clear_updates();
    }
}

setup_metal_result mesh::metal_setup(std::shared_ptr<metal_system> const &system) {
    if (this->_vertex_data) {
        if (auto ul = unless(this->_vertex_data->metal_setup(system))) {
            return ul.value;
        }
    }
    if (this->_index_data) {
        if (auto ul = unless(this->_index_data->metal_setup(system))) {
            return ul.value;
        }
    }
    if (this->_texture) {
        if (auto ul = unless(this->_texture->metal_setup(system))) {
            return ul.value;
        }
    }
    return setup_metal_result{nullptr};
}

bool mesh::_is_mesh_data_exists() {
    if (this->_vertex_data && this->_vertex_data->count() > 0 && this->_index_data && this->_index_data->count()) {
        return true;
    } else {
        return false;
    }
}

bool mesh::_needs_write(batch_building_type const &building_type) {
    if (building_type == batch_building_type::rebuild) {
        return true;
    }

    if (building_type == batch_building_type::overwrite) {
        static mesh_updates_t const _mesh_overwrite_updates = {
            mesh_update_reason::color, mesh_update_reason::use_mesh_color, mesh_update_reason::matrix};

        if (this->_updates.and_test(_mesh_overwrite_updates)) {
            return true;
        }

        if (this->_vertex_data) {
            static mesh_data_updates_t const _overwrite_updates = {mesh_data_update_reason::data_content};

            if (this->_vertex_data->updates().and_test(_overwrite_updates)) {
                return true;
            }
        }

        if (this->_index_data) {
            static mesh_data_updates_t const _overwrite_updates = {mesh_data_update_reason::data_content};

            if (this->_index_data->updates().and_test(_overwrite_updates)) {
                return true;
            }
        }
    }

    return false;
}

std::shared_ptr<mesh> mesh::make_shared() {
    return make_shared({}, nullptr, nullptr, nullptr);
}

std::shared_ptr<mesh> mesh::make_shared(mesh_args &&args, std::shared_ptr<mesh_vertex_data> const &vertex_data,
                                        std::shared_ptr<mesh_index_data> const &index_data,
                                        std::shared_ptr<ui::texture> const &texture) {
    return std::shared_ptr<mesh>(new mesh{std::move(args), vertex_data, index_data, texture});
}
