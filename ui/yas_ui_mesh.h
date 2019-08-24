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

struct mesh final {
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

    ui::metal_object &metal();
    ui::renderable_mesh &renderable();

    [[nodiscard]] static mesh_ptr make_shared();

   private:
    std::shared_ptr<impl> _impl;

    ui::metal_object _metal_object = nullptr;
    ui::renderable_mesh _renderable = nullptr;

    mesh();

    mesh(mesh const &) = delete;
    mesh(mesh &&) = delete;
    mesh &operator=(mesh const &) = delete;
    mesh &operator=(mesh &&) = delete;
};
}  // namespace yas::ui
