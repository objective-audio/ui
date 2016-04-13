//
//  yas_ui_mesh.h
//

#pragma once

#include <vector>
#include "yas_base.h"
#include "yas_ui_mesh_protocol.h"
#include "yas_ui_metal_protocol.h"
#include "yas_ui_shared_types.h"
#include "yas_ui_types.h"

namespace yas {
namespace ui {
    class texture;

    class mesh_data : public base {
        using super_class = base;

       public:
        mesh_data(UInt32 const vertex_count, UInt32 const index_count);
        mesh_data(std::nullptr_t);

        const ui::vertex2d_t *vertices() const;
        UInt32 vertex_count() const;
        const UInt16 *indices() const;
        UInt32 index_count() const;

        void write(std::function<void(std::vector<ui::vertex2d_t> &, std::vector<UInt16> &)> const &);

        ui::metal_object metal();
        ui::renderable_mesh_data renderable();

       protected:
        class impl;

        mesh_data(std::shared_ptr<impl> &&);
    };

    class dynamic_mesh_data : public mesh_data {
        using super_class = mesh_data;

       public:
        dynamic_mesh_data(UInt32 const max_vertex_count, UInt32 const max_index_count);
        dynamic_mesh_data(std::nullptr_t);

        void set_vertex_count(UInt32 const);
        void set_index_count(UInt32 const);

       private:
        class impl;
    };

    class mesh : public base {
        using super_class = base;

       public:
        mesh();
        mesh(std::nullptr_t);

        ui::mesh_data const &data() const;
        ui::texture const &texture() const;
        simd::float4 const &color() const;
        ui::primitive_type const &primitive_type() const;

        void set_data(ui::mesh_data);
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
