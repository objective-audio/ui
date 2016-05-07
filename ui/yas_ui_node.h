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

        ui::point position() const;
        float angle() const;
        ui::size scale() const;
        ui::color color() const;
        float alpha() const;
        bool is_enabled() const;

        ui::mesh const &mesh() const;
        ui::mesh &mesh();
        ui::collider const &collider() const;
        ui::collider &collider();

        void set_position(ui::point);
        void set_angle(float const);
        void set_scale(ui::size);
        void set_color(ui::color);
        void set_alpha(float const);
        void set_mesh(ui::mesh);
        void set_collider(ui::collider);
        void set_enabled(bool const);

        void push_front_sub_node(ui::node);
        void push_back_sub_node(ui::node);
        void insert_sub_node(ui::node, std::size_t const);
        void remove_from_super_node();

        std::vector<ui::node> const &children() const;
        ui::node parent() const;

        ui::renderer renderer() const;

        void update_render_info(render_info &info);

        ui::metal_object metal();
        ui::renderable_node renderable();

        subject_t &subject();
        void dispatch_method(ui::node_method const);

        ui::point convert_position(ui::point const &) const;
    };
}
}
