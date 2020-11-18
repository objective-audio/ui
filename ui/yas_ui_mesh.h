//
//  yas_ui_mesh.h
//

#pragma once

#include <ui/yas_ui_mesh_data.h>
#include <ui/yas_ui_mesh_protocol.h>
#include <ui/yas_ui_metal_protocol.h>
#include <ui/yas_ui_ptr.h>

namespace yas::ui {
class texture;
enum class primitive_type;

struct mesh final : renderable_mesh, metal_object {
    virtual ~mesh();

    ui::mesh_data_ptr const &mesh_data() const;
    ui::texture_ptr const &texture() const;
    simd::float4 const &color() const;
    bool is_use_mesh_color() const;
    ui::primitive_type const &primitive_type() const;

    void set_mesh_data(ui::mesh_data_ptr const &);
    void set_texture(ui::texture_ptr const &);
    void set_color(simd::float4 const &);
    void set_use_mesh_color(bool const);
    void set_primitive_type(ui::primitive_type const);

    [[nodiscard]] static mesh_ptr make_shared();

   private:
    ui::mesh_data_ptr _mesh_data = nullptr;
    ui::texture_ptr _texture = nullptr;
    ui::primitive_type _primitive_type = ui::primitive_type::triangle;
    simd::float4 _color = 1.0f;
    bool _use_mesh_color = false;

    simd::float4x4 _matrix = matrix_identity_float4x4;

    mesh_updates_t _updates;

    mesh();

    mesh(mesh const &) = delete;
    mesh(mesh &&) = delete;
    mesh &operator=(mesh const &) = delete;
    mesh &operator=(mesh &&) = delete;

    simd::float4x4 const &matrix() override;
    void set_matrix(simd::float4x4 const &) override;
    std::size_t render_vertex_count() override;
    std::size_t render_index_count() override;
    mesh_updates_t const &updates() override;
    bool pre_render() override;
    void batch_render(batch_render_mesh_info &, ui::batch_building_type const) override;
    bool is_rendering_color_exists() override;
    void clear_updates() override;

    ui::setup_metal_result metal_setup(std::shared_ptr<ui::metal_system> const &) override;

    bool _is_mesh_data_exists();
    bool _needs_write(ui::batch_building_type const &);
};
}  // namespace yas::ui
