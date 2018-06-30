//
//  yas_ui_node.h
//

#pragma once

#include <vector>
#include "yas_base.h"
#include "yas_flow.h"
#include "yas_ui_metal_protocol.h"
#include "yas_ui_node_protocol.h"

namespace yas::ui {
class mesh;
class render_info;
class collider;
class point;
class size;
class color;
class angle;
class batch;
class render_target;
class layout_guide;
class layout_guide_point;

class node : public base {
   public:
    class impl;

    enum class method {
        added_to_super,
        removed_from_super,
    };

    node();
    node(std::nullptr_t);

    virtual ~node() final;

    bool operator==(node const &) const;
    bool operator!=(node const &) const;

    flow::property<ui::point> const &position() const;
    flow::property<ui::point> &position();
    flow::property<ui::angle> const &angle() const;
    flow::property<ui::angle> &angle();
    flow::property<ui::size> const &scale() const;
    flow::property<ui::size> &scale();
    flow::property<ui::color> const &color() const;
    flow::property<ui::color> &color();
    flow::property<float> const &alpha() const;
    flow::property<float> &alpha();
    flow::property<bool> const &is_enabled() const;
    flow::property<bool> &is_enabled();

    simd::float4x4 const &matrix() const;
    simd::float4x4 const &local_matrix() const;

    flow::property<ui::mesh> const &mesh() const;
    flow::property<ui::mesh> &mesh();
    flow::property<ui::collider> const &collider() const;
    flow::property<ui::collider> &collider();
    flow::property<ui::batch> const &batch() const;
    flow::property<ui::batch> &batch();
    flow::property<ui::render_target> const &render_target() const;
    flow::property<ui::render_target> &render_target();

    void add_sub_node(ui::node);
    void add_sub_node(ui::node, std::size_t const);
    void remove_from_super_node();

    std::vector<ui::node> const &children() const;
    std::vector<ui::node> &children();
    ui::node parent() const;

    ui::renderer renderer() const;

    ui::metal_object &metal();
    ui::renderable_node &renderable();

    using flow_pair_t = std::pair<method, node>;
    [[nodiscard]] flow::node_t<flow_pair_t, false> begin_flow(method const &) const;
    [[nodiscard]] flow::node_t<flow_pair_t, false> begin_flow(std::vector<method> const &) const;

    [[nodiscard]] flow::node<ui::renderer, weak<ui::renderer>, weak<ui::renderer>, true> begin_renderer_flow() const;
    [[nodiscard]] flow::node<ui::node, weak<ui::node>, weak<ui::node>, true> begin_parent_flow() const;

    ui::point convert_position(ui::point const &) const;

    void attach_x_layout_guide(ui::layout_guide &);
    void attach_y_layout_guide(ui::layout_guide &);
    void attach_position_layout_guides(ui::layout_guide_point &);

   private:
    ui::metal_object _metal_object = nullptr;
    ui::renderable_node _renderable = nullptr;
};
}  // namespace yas::ui

namespace yas {
std::string to_string(ui::node::method const &);
}

std::ostream &operator<<(std::ostream &os, yas::ui::node::method const &);
