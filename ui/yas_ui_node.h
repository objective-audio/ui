//
//  yas_ui_node.h
//

#pragma once

#include <chaining/yas_chaining_umbrella.h>
#include <vector>
#include "yas_ui_action.h"
#include "yas_ui_collider.h"
#include "yas_ui_mesh.h"
#include "yas_ui_metal_protocol.h"
#include "yas_ui_node_protocol.h"

namespace yas::ui {
class render_info;
class point;
class size;
class color;
class angle;
class batch;
class layout_guide;
class layout_guide_point;

struct node final : action_target, metal_object, std::enable_shared_from_this<node> {
    class impl;

    enum class method {
        added_to_super,
        removed_from_super,
    };

    virtual ~node();

    chaining::value::holder_ptr<ui::point> const &position() const;
    chaining::value::holder_ptr<ui::point> &position();
    chaining::value::holder_ptr<ui::angle> const &angle() const;
    chaining::value::holder_ptr<ui::angle> &angle();
    chaining::value::holder_ptr<ui::size> const &scale() const;
    chaining::value::holder_ptr<ui::size> &scale();
    chaining::value::holder_ptr<ui::color> const &color() const;
    chaining::value::holder_ptr<ui::color> &color();
    chaining::value::holder_ptr<float> const &alpha() const;
    chaining::value::holder_ptr<float> &alpha();
    chaining::value::holder_ptr<bool> const &is_enabled() const;
    chaining::value::holder_ptr<bool> &is_enabled();

    simd::float4x4 const &matrix() const;
    simd::float4x4 const &local_matrix() const;

    chaining::value::holder_ptr<ui::mesh_ptr> const &mesh() const;
    chaining::value::holder_ptr<ui::mesh_ptr> &mesh();
    chaining::value::holder_ptr<ui::collider_ptr> const &collider() const;
    chaining::value::holder_ptr<ui::collider_ptr> &collider();
    chaining::value::holder_ptr<std::shared_ptr<ui::batch>> const &batch() const;
    chaining::value::holder_ptr<std::shared_ptr<ui::batch>> &batch();
    chaining::value::holder_ptr<ui::render_target_ptr> const &render_target() const;

    void add_sub_node(ui::node_ptr);
    void add_sub_node(ui::node_ptr, std::size_t const);
    void remove_from_super_node();

    std::vector<ui::node_ptr> const &children() const;
    std::vector<ui::node_ptr> &children();
    ui::node_ptr parent() const;

    ui::renderer_ptr renderer() const;

    ui::metal_object_ptr metal();
    ui::renderable_node &renderable();

    using chain_pair_t = std::pair<method, node_ptr>;
    [[nodiscard]] chaining::chain_unsync_t<chain_pair_t> chain(method const &) const;
    [[nodiscard]] chaining::chain_unsync_t<chain_pair_t> chain(std::vector<method> const &) const;

    [[nodiscard]] chaining::chain_relayed_sync_t<ui::renderer_ptr, ui::renderer_wptr> chain_renderer() const;
    [[nodiscard]] chaining::chain_relayed_sync_t<ui::node_ptr, ui::node_wptr> chain_parent() const;

    ui::point convert_position(ui::point const &) const;

    void attach_x_layout_guide(ui::layout_guide &);
    void attach_y_layout_guide(ui::layout_guide &);
    void attach_position_layout_guides(ui::layout_guide_point &);

    [[nodiscard]] static std::shared_ptr<node> make_shared();

   private:
    std::shared_ptr<impl> _impl;

    ui::renderable_node _renderable = nullptr;

    node();

    node(node const &) = delete;
    node(node &&) = delete;
    node &operator=(node const &) = delete;
    node &operator=(node &&) = delete;

    void _prepare(ui::node_ptr const &node);

    ui::setup_metal_result metal_setup(std::shared_ptr<ui::metal_system> const &) override;
};
}  // namespace yas::ui

namespace yas {
std::string to_string(ui::node::method const &);
}

std::ostream &operator<<(std::ostream &os, yas::ui::node::method const &);

namespace yas {
bool operator==(yas::ui::node_wptr const &, yas::ui::node_wptr const &);
bool operator!=(yas::ui::node_wptr const &, yas::ui::node_wptr const &);
namespace ui {
    bool operator==(yas::ui::node_wptr const &, yas::ui::node_wptr const &);
    bool operator!=(yas::ui::node_wptr const &, yas::ui::node_wptr const &);
}  // namespace ui
}  // namespace yas
