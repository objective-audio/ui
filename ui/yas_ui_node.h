//
//  yas_ui_node.h
//

#pragma once

#include <chaining/yas_chaining_umbrella.h>
#include <ui/yas_ui_action.h>
#include <ui/yas_ui_collider.h>
#include <ui/yas_ui_mesh.h>
#include <ui/yas_ui_metal_protocol.h>
#include <ui/yas_ui_node_protocol.h>
#include <ui/yas_ui_renderer.h>
#include <ui/yas_ui_renderer_protocol.h>

#include <vector>

namespace yas::ui {
class render_info;
class point;
class size;
class color;
class angle;
class batch;
class layout_guide;
class layout_guide_point;

struct node final : action_target, metal_object, renderable_node {
    enum class method {
        added_to_super,
        removed_from_super,
    };

    virtual ~node();

    observing::value::holder_ptr<ui::point> const &position() const;
    observing::value::holder_ptr<ui::angle> const &angle() const;
    observing::value::holder_ptr<ui::size> const &scale() const;
    observing::value::holder_ptr<ui::color> const &color() const;
    observing::value::holder_ptr<float> const &alpha() const;
    observing::value::holder_ptr<bool> const &is_enabled() const;

    simd::float4x4 const &matrix() const;
    simd::float4x4 const &local_matrix() const;

    observing::value::holder_ptr<ui::mesh_ptr> const &mesh() const;
    observing::value::holder_ptr<ui::collider_ptr> const &collider() const;
    observing::value::holder_ptr<std::shared_ptr<ui::batch>> const &batch() const;
    observing::value::holder_ptr<ui::render_target_ptr> const &render_target() const;

    void add_sub_node(ui::node_ptr const &);
    void add_sub_node(ui::node_ptr const &, std::size_t const);
    void remove_from_super_node();

    std::vector<ui::node_ptr> const &children() const;
    std::vector<ui::node_ptr> &children();
    ui::node_ptr parent() const;

    ui::renderer_ptr renderer() const override;

    using chain_pair_t = std::pair<method, ui::node const *>;
    [[nodiscard]] observing::canceller_ptr observe(method const &, observing::caller<chain_pair_t>::handler_f &&);
    [[nodiscard]] observing::canceller_ptr observe(std::vector<method> const &,
                                                   observing::caller<chain_pair_t>::handler_f &&);

    [[nodiscard]] observing::canceller_ptr observe_renderer(observing::caller<ui::renderer_ptr>::handler_f &&,
                                                            bool const sync);
    [[nodiscard]] observing::canceller_ptr observe_parent(observing::caller<ui::node_ptr>::handler_f &&,
                                                          bool const sync);

    ui::point convert_position(ui::point const &) const;

    void attach_x_layout_guide(ui::layout_guide &);
    void attach_y_layout_guide(ui::layout_guide &);
    void attach_position_layout_guides(ui::layout_guide_point &);

    [[nodiscard]] static std::shared_ptr<node> make_shared();

   private:
    std::weak_ptr<node> _weak_node;

    observing::value::holder_ptr<ui::node_wptr> const _parent;
    observing::value::holder_ptr<ui::renderer_wptr> const _renderer;

    observing::value::holder_ptr<ui::point> const _position;
    observing::value::holder_ptr<ui::angle> const _angle;
    observing::value::holder_ptr<ui::size> const _scale;
    observing::value::holder_ptr<ui::color> const _color;
    observing::value::holder_ptr<float> const _alpha;
    observing::value::holder_ptr<ui::mesh_ptr> const _mesh;
    observing::value::holder_ptr<ui::collider_ptr> const _collider;
    observing::value::holder_ptr<std::shared_ptr<ui::batch>> const _batch;
    observing::value::holder_ptr<ui::render_target_ptr> const _render_target;
    observing::value::holder_ptr<bool> const _enabled;

    observing::canceller_pool _pool;
    observing::cancellable_ptr _x_canceller = nullptr;
    observing::cancellable_ptr _y_canceller = nullptr;
    observing::cancellable_ptr _position_canceller = nullptr;

    std::vector<ui::node_ptr> _children;

    mutable simd::float4x4 _matrix = matrix_identity_float4x4;
    mutable simd::float4x4 _local_matrix = matrix_identity_float4x4;

    mutable std::unordered_map<ui::node::method, observing::canceller_ptr> _dispatch_cancellers;
    observing::notifier_ptr<chain_pair_t> const _dispatch_notifier = observing::notifier<chain_pair_t>::make_shared();
    observing::notifier_ptr<ui::node::method> const _notifier = observing::notifier<ui::node::method>::make_shared();

    node_updates_t _updates;

    node();

    node(node const &) = delete;
    node(node &&) = delete;
    node &operator=(node const &) = delete;
    node &operator=(node &&) = delete;

    ui::setup_metal_result metal_setup(std::shared_ptr<ui::metal_system> const &) override;

    void set_renderer(ui::renderer_ptr const &) override;
    void fetch_updates(ui::tree_updates &) override;
    void build_render_info(ui::render_info &) override;
    bool is_rendering_color_exists() override;
    void clear_updates() override;

    void _add_sub_node(ui::node_ptr &sub_node);
    void _remove_sub_node(ui::node_ptr const &sub_node);
    void _set_renderer_recursively(ui::renderer_ptr const &);
    void _update_mesh_color();
    void _set_updated(ui::node_update_reason const);
    void _update_local_matrix() const;
    void _update_matrix() const;
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
