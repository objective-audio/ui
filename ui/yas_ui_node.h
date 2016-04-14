//
//  yas_ui_node.h
//

#pragma once

#include <Metal/Metal.h>
#include <simd/simd.h>
#include <vector>
#include "yas_base.h"
#include "yas_ui_metal_protocol.h"
#include "yas_ui_node_protocol.h"

namespace yas {
namespace ui {
    class mesh;
    class render_info;
    class touch;

    class node : public base {
        using super_class = base;

       public:
        node();
        node(std::nullptr_t);

        bool operator==(node const &) const;
        bool operator!=(node const &) const;

        simd::float2 position() const;
        Float32 angle() const;
        simd::float2 scale() const;
        simd::float4 color() const;
        ui::mesh mesh() const;
        ui::touch touch() const;
        bool is_enabled() const;

        void set_position(simd::float2 const);
        void set_angle(Float32 const);
        void set_scale(simd::float2 const);
        void set_color(simd::float4 const);
        void set_mesh(ui::mesh);
        void set_touch(ui::touch);
        void set_enabled(bool const);

        void add_sub_node(ui::node);
        void remove_from_super_node();

        std::vector<ui::node> const &children() const;
        ui::node parent() const;

        void update_render_info(render_info &info);

        ui::metal_object metal();
        ui::renderable_node renderable();

        simd::float2 convert_position(simd::float2 const &);

       public:
        class impl;

       protected:
        node(std::shared_ptr<impl> &&);
    };
}
}

#include "yas_ui_node_impl.h"
