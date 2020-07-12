//
//  yas_ui_mesh.mm
//

#include "yas_ui_mesh.h"
#include <cpp_utils/yas_fast_each.h>
#include <cpp_utils/yas_objc_ptr.h>
#include <cpp_utils/yas_unless.h>
#include "yas_ui_batch_protocol.h"
#include "yas_ui_batch_render_mesh_info.h"
#include "yas_ui_mesh_data.h"
#include "yas_ui_metal_encode_info.h"
#include "yas_ui_metal_system.h"
#include "yas_ui_metal_types.h"
#include "yas_ui_renderer.h"
#include "yas_ui_texture.h"

using namespace yas;

#pragma mark - ui::mesh

ui::mesh::mesh() {
    this->_updates.flags.set();
}

ui::mesh::~mesh() = default;

ui::mesh_data_ptr const &ui::mesh::mesh_data() const {
    return this->_mesh_data;
}

ui::texture_ptr const &ui::mesh::texture() const {
    return this->_texture;
}

simd::float4 const &ui::mesh::color() const {
    return this->_color;
}

bool ui::mesh::is_use_mesh_color() const {
    return this->_use_mesh_color;
}

ui::primitive_type const &ui::mesh::primitive_type() const {
    return this->_primitive_type;
}

void ui::mesh::set_mesh_data(ui::mesh_data_ptr const &mesh_data) {
    if (this->_mesh_data != mesh_data) {
        this->_mesh_data = std::move(mesh_data);

        if (this->_is_color_exists()) {
            this->_updates.set(ui::mesh_update_reason::mesh_data);
        }
    }
}

void ui::mesh::set_texture(ui::texture_ptr const &texture) {
    if (this->_texture != texture) {
        this->_texture = texture;

        if (this->is_rendering_color_exists()) {
            this->_updates.set(ui::mesh_update_reason::texture);
        }
    }
}

void ui::mesh::set_color(simd::float4 const &color) {
    if (!yas::is_equal(this->_color, color)) {
        bool const is_prev_alpha_exists = this->_color[3] != 0.0f;

        this->_color = color;

        if (this->_is_mesh_data_exists() && !this->_use_mesh_color) {
            this->_updates.set(ui::mesh_update_reason::color);

            bool const is_next_alpha_exists = color[3] != 0.0f;
            if (is_prev_alpha_exists != is_next_alpha_exists) {
                this->_updates.set(ui::mesh_update_reason::alpha_exists);
            }
        }
    }
}

void ui::mesh::set_use_mesh_color(bool const use) {
    if (this->_use_mesh_color != use) {
        this->_use_mesh_color = use;

        if (this->_is_mesh_data_exists()) {
            this->_updates.set(ui::mesh_update_reason::use_mesh_color);
        }
    }
}

void ui::mesh::set_primitive_type(ui::primitive_type const type) {
    if (this->_primitive_type != type) {
        this->_primitive_type = type;

        if (this->is_rendering_color_exists()) {
            this->_updates.set(ui::mesh_update_reason::primitive_type);
        }
    }
}

simd::float4x4 const &ui::mesh::matrix() {
    return this->_matrix;
}

void ui::mesh::set_matrix(simd::float4x4 const &matrix) {
    if (this->_matrix != matrix) {
        this->_matrix = matrix;

        if (this->is_rendering_color_exists()) {
            this->_updates.set(ui::mesh_update_reason::matrix);
        }
    }
}

std::size_t ui::mesh::render_vertex_count() {
    if (this->is_rendering_color_exists()) {
        return this->_mesh_data->vertex_count();
    }
    return 0;
}

std::size_t ui::mesh::render_index_count() {
    if (this->is_rendering_color_exists()) {
        return this->_mesh_data->index_count();
    }
    return 0;
}

ui::mesh_updates_t const &ui::mesh::updates() {
    return this->_updates;
}

bool ui::mesh::pre_render() {
    if (this->_mesh_data) {
        ui::renderable_mesh_data::cast(this->_mesh_data)->update_render_buffer();
        return this->is_rendering_color_exists();
    }

    return false;
}

void ui::mesh::batch_render(batch_render_mesh_info &mesh_info, ui::batch_building_type const building_type) {
    if (this->_needs_write(building_type)) {
        mesh_info.mesh_data->write([&src_mesh_data = this->_mesh_data, &matrix = this->_matrix, &color = this->_color,
                                    is_use_mesh_color = this->_use_mesh_color,
                                    &mesh_info](auto &vertices, auto &indices) {
            auto const dst_index_offset = static_cast<index2d_t>(mesh_info.index_idx);
            auto const dst_vertex_offset = static_cast<index2d_t>(mesh_info.vertex_idx);

            auto *dst_indices = &indices[dst_index_offset];
            auto const *src_indices = src_mesh_data->indices();

            auto each = make_fast_each(src_mesh_data->index_count());
            while (yas_each_next(each)) {
                auto const &idx = yas_each_index(each);
                dst_indices[idx] = src_indices[idx] + dst_vertex_offset;
            }

            auto *dst_vertices = &vertices[dst_vertex_offset];
            auto const *src_vertices = src_mesh_data->vertices();

            each = make_fast_each(src_mesh_data->vertex_count());
            while (yas_each_next(each)) {
                auto &idx = yas_each_index(each);
                auto &dst_vertex = dst_vertices[idx];
                auto &src_vertex = src_vertices[idx];
                dst_vertex.position = to_float2(matrix * to_float4(src_vertex.position));
                dst_vertex.tex_coord = src_vertex.tex_coord;
                dst_vertex.color = is_use_mesh_color ? src_vertex.color * color : color;
            }
        });
    }

    mesh_info.vertex_idx += this->_mesh_data->vertex_count();
    mesh_info.index_idx += this->_mesh_data->index_count();
}

bool ui::mesh::is_rendering_color_exists() {
    return this->_is_mesh_data_exists() && this->_is_color_exists();
}

void ui::mesh::clear_updates() {
    this->_updates.flags.reset();

    if (this->_mesh_data) {
        ui::renderable_mesh_data::cast(this->_mesh_data)->clear_updates();
    }
}

ui::setup_metal_result ui::mesh::metal_setup(std::shared_ptr<ui::metal_system> const &system) {
    if (this->_mesh_data) {
        if (auto ul = unless(ui::metal_object::cast(this->_mesh_data)->metal_setup(system))) {
            return ul.value;
        }
    }
    if (this->_texture) {
        if (auto ul = unless(ui::metal_object::cast(this->_texture)->metal_setup(system))) {
            return ul.value;
        }
    }
    return ui::setup_metal_result{nullptr};
}

bool ui::mesh::_is_mesh_data_exists() {
    return this->_mesh_data && this->_mesh_data->index_count() > 0;
}

bool ui::mesh::_is_color_exists() {
    if (!this->_use_mesh_color) {
        static simd::float4 const _clear_color = 0.0f;
        if (yas::is_equal(this->_color, _clear_color)) {
            return false;
        }
    }
    return true;
}

bool ui::mesh::_needs_write(ui::batch_building_type const &building_type) {
    if (building_type == ui::batch_building_type::rebuild) {
        return true;
    }

    if (building_type == ui::batch_building_type::overwrite) {
        static mesh_updates_t const _mesh_overwrite_updates = {
            ui::mesh_update_reason::color, ui::mesh_update_reason::use_mesh_color, ui::mesh_update_reason::matrix};

        if (this->_updates.and_test(_mesh_overwrite_updates)) {
            return true;
        }

        if (this->_mesh_data) {
            static mesh_data_updates_t const _mesh_data_overwrite_updates = {ui::mesh_data_update_reason::data};

            if (ui::renderable_mesh_data::cast(this->_mesh_data)->updates().and_test(_mesh_data_overwrite_updates)) {
                return true;
            }
        }
    }

    return false;
}

ui::mesh_ptr ui::mesh::make_shared() {
    return std::shared_ptr<mesh>(new mesh{});
}
