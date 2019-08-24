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

#pragma mark - ui::mesh::impl

struct ui::mesh::impl : renderable_mesh::impl, metal_object::impl {
    impl() {
        this->_updates.flags.set();
    }

    ui::setup_metal_result metal_setup(ui::metal_system_ptr const &metal_system) override {
        if (this->_mesh_data) {
            if (auto ul = unless(this->_mesh_data->metal().metal_setup(metal_system))) {
                return ul.value;
            }
        }
        if (this->_texture) {
            if (auto ul = unless(this->_texture->metal().metal_setup(metal_system))) {
                return ul.value;
            }
        }
        return ui::setup_metal_result{nullptr};
    }

    simd::float4x4 const &matrix() override {
        return this->_matrix;
    }

    void set_matrix(simd::float4x4 &&matrix) override {
        if (this->_matrix != matrix) {
            this->_matrix = std::move(matrix);

            if (this->is_rendering_color_exists()) {
                this->_updates.set(ui::mesh_update_reason::matrix);
            }
        }
    }

    std::size_t render_vertex_count() override {
        if (this->is_rendering_color_exists()) {
            return this->_mesh_data->vertex_count();
        }
        return 0;
    }

    std::size_t render_index_count() override {
        if (this->is_rendering_color_exists()) {
            return this->_mesh_data->index_count();
        }
        return 0;
    }

    ui::mesh_updates_t const &updates() override {
        return this->_updates;
    }

    bool pre_render() override {
        if (this->_mesh_data) {
            this->_mesh_data->renderable().update_render_buffer();
            return this->is_rendering_color_exists();
        }

        return false;
    }

    void batch_render(ui::batch_render_mesh_info &mesh_info, ui::batch_building_type const building_type) override {
        if (this->_needs_write(building_type)) {
            mesh_info.mesh_data->write([&src_mesh_data = this->_mesh_data, &matrix = this->_matrix,
                                        &color = this->_color, is_use_mesh_color = this->_use_mesh_color,
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

    void clear_updates() override {
        this->_updates.flags.reset();

        if (this->_mesh_data) {
            this->_mesh_data->renderable().clear_updates();
        }
    }

    ui::mesh_data_ptr const &mesh_data() {
        return this->_mesh_data;
    }

    ui::texture_ptr const &texture() {
        return this->_texture;
    }

    ui::primitive_type &primitive_type() {
        return this->_primitive_type;
    }

    simd::float4 &color() {
        return this->_color;
    }

    bool is_use_mesh_color() {
        return this->_use_mesh_color;
    }

    void set_mesh_data(ui::mesh_data_ptr &&mesh_data) {
        if (this->_mesh_data != mesh_data) {
            this->_mesh_data = std::move(mesh_data);

            if (this->_is_color_exists()) {
                this->_updates.set(ui::mesh_update_reason::mesh_data);
            }
        }
    }

    void set_texture(ui::texture_ptr const &texture) {
        if (this->_texture != texture) {
            this->_texture = texture;

            if (this->is_rendering_color_exists()) {
                this->_updates.set(ui::mesh_update_reason::texture);
            }
        }
    }

    void set_primitive_type(ui::primitive_type const type) {
        if (this->_primitive_type != type) {
            this->_primitive_type = type;

            if (this->is_rendering_color_exists()) {
                this->_updates.set(ui::mesh_update_reason::primitive_type);
            }
        }
    }

    void set_color(simd::float4 &&color) {
        if (!yas::is_equal(_color, color)) {
            this->_color = std::move(color);

            if (this->_is_mesh_data_exists() && !this->_use_mesh_color) {
                this->_updates.set(ui::mesh_update_reason::color);
            }
        }
    }

    void set_use_mesh_color(bool const use) {
        if (this->_use_mesh_color != use) {
            this->_use_mesh_color = use;

            if (this->_is_mesh_data_exists()) {
                this->_updates.set(ui::mesh_update_reason::use_mesh_color);
            }
        }
    }

    bool is_rendering_color_exists() override {
        return this->_is_mesh_data_exists() && this->_is_color_exists();
    }

   private:
    bool _is_mesh_data_exists() {
        return this->_mesh_data && this->_mesh_data->index_count() > 0;
    }

    bool _is_color_exists() {
        if (!this->_use_mesh_color) {
            static simd::float4 const _clear_color = 0.0f;
            if (yas::is_equal(this->_color, _clear_color)) {
                return false;
            }
        }
        return true;
    }

    bool _needs_write(ui::batch_building_type const &building_type) {
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

                if (this->_mesh_data->renderable().updates().and_test(_mesh_data_overwrite_updates)) {
                    return true;
                }
            }
        }

        return false;
    }

    ui::mesh_data_ptr _mesh_data = nullptr;
    ui::texture_ptr _texture = nullptr;
    ui::primitive_type _primitive_type = ui::primitive_type::triangle;
    simd::float4 _color = 1.0f;
    bool _use_mesh_color = false;

    simd::float4x4 _matrix = matrix_identity_float4x4;

    mesh_updates_t _updates;
};

#pragma mark - ui::mesh

ui::mesh::mesh() : _impl(std::make_shared<impl>()) {
}

ui::mesh::~mesh() = default;

ui::mesh_data_ptr const &ui::mesh::mesh_data() const {
    return this->_impl->mesh_data();
}

ui::texture_ptr const &ui::mesh::texture() const {
    return this->_impl->texture();
}

simd::float4 const &ui::mesh::color() const {
    return this->_impl->color();
}

bool ui::mesh::is_use_mesh_color() const {
    return this->_impl->is_use_mesh_color();
}

ui::primitive_type const &ui::mesh::primitive_type() const {
    return this->_impl->primitive_type();
}

void ui::mesh::set_mesh_data(ui::mesh_data_ptr data) {
    this->_impl->set_mesh_data(std::move(data));
}

void ui::mesh::set_texture(ui::texture_ptr const &texture) {
    this->_impl->set_texture(texture);
}

void ui::mesh::set_color(simd::float4 color) {
    this->_impl->set_color(std::move(color));
}

void ui::mesh::set_use_mesh_color(bool const use) {
    this->_impl->set_use_mesh_color(use);
}

void ui::mesh::set_primitive_type(ui::primitive_type const type) {
    this->_impl->set_primitive_type(type);
}

ui::mesh_data_ptr const &ui::mesh::mesh_data() {
    return this->_impl->mesh_data();
}

ui::mesh_ptr ui::mesh::make_shared() {
    return std::shared_ptr<mesh>(new mesh{});
}

#pragma mark - protocol

ui::metal_object &ui::mesh::metal() {
    if (!this->_metal_object) {
        this->_metal_object = ui::metal_object{this->_impl};
    }
    return this->_metal_object;
}

ui::renderable_mesh &ui::mesh::renderable() {
    if (!this->_renderable) {
        this->_renderable = ui::renderable_mesh{this->_impl};
    }
    return this->_renderable;
}
