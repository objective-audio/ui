//
//  yas_ui_mesh.h
//

#pragma once

#include "yas_base.h"
#include "yas_ui_mesh_protocol.h"
#include "yas_ui_metal_protocol.h"
#include "yas_ui_types.h"

namespace yas {
namespace ui {
    class texture;
    class mesh_data;

    class mesh : public base {
        using super_class = base;

       public:
        mesh();
        mesh(std::nullptr_t);

        ui::mesh_data const &data() const;
        ui::texture const &texture() const;
        simd::float4 const &color() const;
        ui::primitive_type const &primitive_type() const;

        void set_mesh_data(ui::mesh_data);
        void set_texture(ui::texture);
        void set_color(simd::float4 const);
        void set_primitive_type(ui::primitive_type const);

        ui::metal_object metal();
        ui::renderable_mesh renderable();

       private:
        class impl;
    };
}
}
