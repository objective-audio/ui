//
//  yas_ui_mesh.h
//

#pragma once

#include "yas_ui_mesh_data.h"
#include "yas_ui_mesh_protocol.h"
#include "yas_ui_metal_protocol.h"
#include "yas_ui_ptr.h"

namespace yas::ui {
class texture;
enum class primitive_type;

struct mesh final : renderable_mesh, metal_object, std::enable_shared_from_this<mesh> {
    class impl;

    virtual ~mesh();

    ui::mesh_data_ptr const &mesh_data() const;
    ui::texture_ptr const &texture() const;
    simd::float4 const &color() const;
    bool is_use_mesh_color() const;
    ui::primitive_type const &primitive_type() const;

    ui::mesh_data_ptr const &mesh_data();

    void set_mesh_data(ui::mesh_data_ptr);
    void set_texture(ui::texture_ptr const &);
    void set_color(simd::float4);
    void set_use_mesh_color(bool const);
    void set_primitive_type(ui::primitive_type const);

    ui::metal_object_ptr metal();
    ui::renderable_mesh_ptr renderable();

    [[nodiscard]] static mesh_ptr make_shared();

   private:
    std::unique_ptr<impl> _impl;

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
};
}  // namespace yas::ui
