//
//  yas_ui_node.h
//

#pragma once

#include <vector>
#include "yas_base.h"
#include "yas_ui_metal_protocol.h"
#include "yas_ui_node_protocol.h"

namespace yas {
template <typename T, typename K>
class subject;

namespace ui {
    class mesh;
    class render_info;
    class collider;
    class point;
    class size;
    class color;
    class batch;

    class node : public base {
       public:
        class impl;

        enum class method {
            added_to_super,
            removed_from_super,

            parent_changed,
            renderer_changed,
            position_changed,
            angle_changed,
            scale_changed,
            color_changed,
            alpha_changed,
            mesh_changed,
            collider_changed,
            enabled_changed,
        };

        using subject_t = subject<node, method>;

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

        simd::float4x4 const &matrix() const;
        simd::float4x4 const &local_matrix() const;

        ui::mesh const &mesh() const;
        ui::mesh &mesh();
        ui::collider const &collider() const;
        ui::collider &collider();
        ui::batch const &batch() const;
        ui::batch &batch();

        void set_position(ui::point);
        void set_angle(float const);
        void set_scale(ui::size);
        void set_color(ui::color);
        void set_alpha(float const);
        void set_mesh(ui::mesh);
        void set_collider(ui::collider);
        void set_enabled(bool const);
        void set_batch(ui::batch);

        void push_front_sub_node(ui::node);
        void push_back_sub_node(ui::node);
        void insert_sub_node(ui::node, std::size_t const);
        void remove_from_super_node();

        std::vector<ui::node> const &children() const;
        std::vector<ui::node> &children();
        ui::node parent() const;

        ui::renderer renderer() const;

        ui::metal_object &metal();
        ui::renderable_node &renderable();

        subject_t &subject();
        void dispatch_method(ui::node::method const);

        ui::point convert_position(ui::point const &) const;

       private:
        ui::metal_object _metal_object = nullptr;
        ui::renderable_node _renderable = nullptr;
    };
}

std::string to_string(ui::node::method const &);
}

std::ostream &operator<<(std::ostream &os, yas::ui::node::method const &);
