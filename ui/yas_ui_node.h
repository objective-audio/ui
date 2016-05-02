//
//  yas_ui_node.h
//

#pragma once

#include <Metal/Metal.h>
#include <simd/simd.h>
#include <vector>
#include "yas_base.h"
#include "yas_observing.h"
#include "yas_property.h"
#include "yas_ui_metal_protocol.h"
#include "yas_ui_node_protocol.h"
#include "yas_ui_types.h"

namespace yas {
namespace ui {
    class mesh;
    class render_info;
    class collider;

    class node : public base {
       public:
        class impl;

        using subject_t = subject<node, node_method>;

        node();
        node(std::nullptr_t);

        bool operator==(node const &) const;
        bool operator!=(node const &) const;

        property<ui::point> const &position() const;
        property<float> const &angle() const;
        property<ui::size> const &scale() const;
        property<ui::color> const &color() const;
        property<float> const &alpha() const;
        property<ui::mesh> const &mesh() const;
        property<ui::collider> const &collider() const;
        property<bool> const &enabled() const;

        property<ui::point> &position();
        property<float> &angle();
        property<ui::size> &scale();
        property<ui::color> &color();
        property<float> &alpha();
        property<ui::mesh> &mesh();
        property<ui::collider> &collider();
        property<bool> &enabled();

        void add_sub_node(ui::node);
        void remove_from_super_node();

        std::vector<ui::node> const &children() const;
        ui::node parent() const;

        ui::node_renderer renderer() const;

        void update_render_info(render_info &info);

        ui::metal_object metal();
        ui::renderable_node renderable();

        subject_t &subject();

        simd::float2 convert_position(simd::float2 const &) const;
    };
}
}

#include "yas_ui_node_impl.h"
