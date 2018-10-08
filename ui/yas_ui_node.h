//
//  yas_ui_node.h
//

#pragma once

#include <vector>
#include "yas_base.h"
#include "yas_chaining.h"
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

    chaining::holder<ui::point> const &position() const;
    chaining::holder<ui::point> &position();
    chaining::holder<ui::angle> const &angle() const;
    chaining::holder<ui::angle> &angle();
    chaining::holder<ui::size> const &scale() const;
    chaining::holder<ui::size> &scale();
    chaining::holder<ui::color> const &color() const;
    chaining::holder<ui::color> &color();
    chaining::holder<float> const &alpha() const;
    chaining::holder<float> &alpha();
    chaining::holder<bool> const &is_enabled() const;
    chaining::holder<bool> &is_enabled();

    simd::float4x4 const &matrix() const;
    simd::float4x4 const &local_matrix() const;

    chaining::holder<ui::mesh> const &mesh() const;
    chaining::holder<ui::mesh> &mesh();
    chaining::holder<ui::collider> const &collider() const;
    chaining::holder<ui::collider> &collider();
    chaining::holder<ui::batch> const &batch() const;
    chaining::holder<ui::batch> &batch();
    chaining::holder<ui::render_target> const &render_target() const;
    chaining::holder<ui::render_target> &render_target();

    void add_sub_node(ui::node);
    void add_sub_node(ui::node, std::size_t const);
    void remove_from_super_node();

    std::vector<ui::node> const &children() const;
    std::vector<ui::node> &children();
    ui::node parent() const;

    ui::renderer renderer() const;

    ui::metal_object &metal();
    ui::renderable_node &renderable();

    using chain_pair_t = std::pair<method, node>;
    [[nodiscard]] chaining::chain_unsyncable_t<chain_pair_t> chain(method const &) const;
    [[nodiscard]] chaining::chain_unsyncable_t<chain_pair_t> chain(std::vector<method> const &) const;

    [[nodiscard]] chaining::chain<ui::renderer, weak<ui::renderer>, weak<ui::renderer>, true> chain_renderer() const;
    [[nodiscard]] chaining::chain<ui::node, weak<ui::node>, weak<ui::node>, true> chain_parent() const;

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
