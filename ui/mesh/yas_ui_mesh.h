//
//  yas_ui_mesh.h
//

#pragma once

#include <ui/yas_ui_mesh_types.h>
#include <ui/yas_ui_metal_setup_types.h>
#include <ui/yas_ui_renderer_dependency.h>

namespace yas::ui {
struct mesh final : renderable_mesh {
    [[nodiscard]] std::shared_ptr<mesh_vertex_data> const &vertex_data() const;
    [[nodiscard]] std::shared_ptr<mesh_index_data> const &index_data() const;
    [[nodiscard]] std::shared_ptr<texture> const &texture() const;
    [[nodiscard]] simd::float4 const &color() const;
    [[nodiscard]] bool is_use_mesh_color() const;
    [[nodiscard]] ui::primitive_type const &primitive_type() const;

    void set_vertex_data(std::shared_ptr<mesh_vertex_data> const &);
    void set_index_data(std::shared_ptr<mesh_index_data> const &);
    void set_texture(std::shared_ptr<ui::texture> const &);
    void set_color(simd::float4 const &);
    void set_use_mesh_color(bool const);
    void set_primitive_type(ui::primitive_type const);

    ui::setup_metal_result metal_setup(std::shared_ptr<ui::metal_system> const &);

    [[nodiscard]] static std::shared_ptr<mesh> make_shared();
    [[nodiscard]] static std::shared_ptr<mesh> make_shared(mesh_args &&, std::shared_ptr<mesh_vertex_data> const &,
                                                           std::shared_ptr<mesh_index_data> const &,
                                                           std::shared_ptr<ui::texture> const &);

   private:
    std::shared_ptr<mesh_vertex_data> _vertex_data = nullptr;
    std::shared_ptr<mesh_index_data> _index_data = nullptr;
    std::shared_ptr<ui::texture> _texture = nullptr;
    ui::primitive_type _primitive_type = ui::primitive_type::triangle;
    simd::float4 _color = 1.0f;
    bool _use_mesh_color = false;

    simd::float4x4 _matrix = matrix_identity_float4x4;

    mesh_updates_t _updates;

    mesh(mesh_args &&, std::shared_ptr<mesh_vertex_data> const &, std::shared_ptr<mesh_index_data> const &,
         std::shared_ptr<ui::texture> const &);

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

    bool _is_mesh_data_exists();
    bool _needs_write(ui::batch_building_type const &);
};
}  // namespace yas::ui
