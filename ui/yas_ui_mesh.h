//
//  yas_ui_mesh.h
//

#pragma once

#include "yas_base.h"
#include "yas_ui_mesh_protocol.h"
#include "yas_ui_metal_protocol.h"

namespace yas::ui {
class texture;
class mesh_data;
enum class primitive_type;

class mesh : public base {
    class impl;

   public:
    mesh();
    mesh(std::nullptr_t);

    virtual ~mesh() final;

    ui::mesh_data const &mesh_data() const;
    ui::texture const &texture() const;
    simd::float4 const &color() const;
    bool is_use_mesh_color() const;
    ui::primitive_type const &primitive_type() const;

    ui::mesh_data &mesh_data();
    ui::texture &texture();

    void set_mesh_data(ui::mesh_data);
    void set_texture(ui::texture);
    void set_color(simd::float4);
    void set_use_mesh_color(bool const);
    void set_primitive_type(ui::primitive_type const);

    ui::metal_object &metal();
    ui::renderable_mesh &renderable();

   private:
    ui::metal_object _metal_object = nullptr;
    ui::renderable_mesh _renderable = nullptr;
};
}  // namespace yas::ui
