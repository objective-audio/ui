//
//  yas_ui_node.h
//

#pragma once

#include <observing/yas_observing_umbrella.h>
#include <ui/yas_ui_action_dependency.h>
#include <ui/yas_ui_collider.h>
#include <ui/yas_ui_layout_dependency.h>
#include <ui/yas_ui_mesh.h>
#include <ui/yas_ui_metal_dependency.h>
#include <ui/yas_ui_renderer.h>
#include <ui/yas_ui_renderer_dependency.h>

#include <vector>

namespace yas::ui {
struct node final : action_target, metal_object, renderable_node, layout_point_target {
    enum class method {
        added_to_super,
        removed_from_super,
    };

    virtual ~node();

    void set_position(ui::point &&);
    void set_position(ui::point const &);
    [[nodiscard]] ui::point const &position() const;
    [[nodiscard]] observing::syncable observe_position(observing::caller<ui::point>::handler_f &&);

    void set_angle(ui::angle &&);
    void set_angle(ui::angle const &);
    [[nodiscard]] ui::angle const &angle() const;
    [[nodiscard]] observing::syncable observe_angle(observing::caller<ui::angle>::handler_f &&);

    void set_scale(ui::size &&);
    void set_scale(ui::size const &);
    [[nodiscard]] ui::size const &scale() const;
    [[nodiscard]] observing::syncable observe_scale(observing::caller<ui::size>::handler_f &&);

    void set_color(ui::color &&);
    void set_color(ui::color const &);
    [[nodiscard]] ui::color const &color() const;
    [[nodiscard]] observing::syncable observe_color(observing::caller<ui::color>::handler_f &&);

    void set_alpha(float &&);
    void set_alpha(float const &);
    [[nodiscard]] float const &alpha() const;
    [[nodiscard]] observing::syncable observe_alpha(observing::caller<float>::handler_f &&);

    void set_is_enabled(bool &&);
    void set_is_enabled(bool const &);
    [[nodiscard]] bool const &is_enabled() const;
    [[nodiscard]] observing::syncable observe_is_enabled(observing::caller<bool>::handler_f &&);

    [[nodiscard]] simd::float4x4 const &matrix() const;
    [[nodiscard]] simd::float4x4 const &local_matrix() const;

    void set_mesh(std::shared_ptr<mesh> const &);
    [[nodiscard]] std::shared_ptr<mesh> const &mesh() const;
    [[nodiscard]] observing::syncable observe_mesh(observing::caller<std::shared_ptr<ui::mesh>>::handler_f &&);

    void set_collider(std::shared_ptr<collider> const &);
    [[nodiscard]] std::shared_ptr<collider> const &collider() const;
    [[nodiscard]] observing::syncable observe_collider(observing::caller<std::shared_ptr<ui::collider>>::handler_f &&);

    void set_batch(std::shared_ptr<batch> const &);
    [[nodiscard]] std::shared_ptr<batch> const &batch() const;
    [[nodiscard]] observing::syncable observe_batch(observing::caller<std::shared_ptr<ui::batch>>::handler_f &&);

    void set_render_target(std::shared_ptr<render_target> const &);
    [[nodiscard]] std::shared_ptr<render_target> const &render_target() const;
    [[nodiscard]] observing::syncable observe_render_target(
        observing::caller<std::shared_ptr<ui::render_target>>::handler_f &&);

    void add_sub_node(std::shared_ptr<node> const &);
    void add_sub_node(std::shared_ptr<node> const &, std::size_t const);
    void remove_from_super_node();

    [[nodiscard]] std::vector<std::shared_ptr<node>> const &children() const;
    [[nodiscard]] std::vector<std::shared_ptr<node>> &children();
    [[nodiscard]] std::shared_ptr<node> parent() const;

    [[nodiscard]] std::shared_ptr<ui::renderer> renderer() const override;

    [[nodiscard]] observing::endable observe(observing::caller<method>::handler_f &&);
    [[nodiscard]] observing::syncable observe_renderer(observing::caller<std::shared_ptr<ui::renderer>>::handler_f &&);
    [[nodiscard]] observing::syncable observe_parent(observing::caller<std::shared_ptr<node>>::handler_f &&);

    [[nodiscard]] ui::point convert_position(ui::point const &) const;

    void attach_x_layout_guide(ui::layout_value_guide &);
    void attach_y_layout_guide(ui::layout_value_guide &);
    void attach_position_layout_guides(ui::layout_point_guide &);

    [[nodiscard]] static std::shared_ptr<node> make_shared();

   private:
    std::weak_ptr<node> _weak_node;

    observing::value::holder_ptr<std::weak_ptr<node>> const _parent;
    observing::value::holder_ptr<std::weak_ptr<ui::renderer>> const _renderer;

    observing::value::holder_ptr<ui::point> const _position;
    observing::value::holder_ptr<ui::angle> const _angle;
    observing::value::holder_ptr<ui::size> const _scale;
    observing::value::holder_ptr<ui::color> const _color;
    observing::value::holder_ptr<float> const _alpha;
    observing::value::holder_ptr<std::shared_ptr<ui::mesh>> const _mesh;
    observing::value::holder_ptr<std::shared_ptr<ui::collider>> const _collider;
    observing::value::holder_ptr<std::shared_ptr<ui::batch>> const _batch;
    observing::value::holder_ptr<std::shared_ptr<ui::render_target>> const _render_target;
    observing::value::holder_ptr<bool> const _enabled;

    observing::canceller_pool _pool;
    observing::cancellable_ptr _x_canceller = nullptr;
    observing::cancellable_ptr _y_canceller = nullptr;
    observing::cancellable_ptr _position_canceller = nullptr;

    std::vector<std::shared_ptr<node>> _children;

    mutable simd::float4x4 _matrix = matrix_identity_float4x4;
    mutable simd::float4x4 _local_matrix = matrix_identity_float4x4;

    observing::notifier_ptr<ui::node::method> const _notifier = observing::notifier<ui::node::method>::make_shared();

    node_updates_t _updates;

    node();

    node(node const &) = delete;
    node(node &&) = delete;
    node &operator=(node const &) = delete;
    node &operator=(node &&) = delete;

    ui::setup_metal_result metal_setup(std::shared_ptr<ui::metal_system> const &) override;

    void set_renderer(std::shared_ptr<ui::renderer> const &) override;
    void fetch_updates(ui::tree_updates &) override;
    void build_render_info(ui::render_info &) override;
    bool is_rendering_color_exists() override;
    void clear_updates() override;

    void set_layout_point(ui::point const &) override;

    void _add_sub_node(std::shared_ptr<node> &sub_node);
    void _remove_sub_node(ui::node *sub_node);
    void _remove_sub_nodes_on_destructor();
    void _set_renderer_recursively(std::shared_ptr<ui::renderer> const &);
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
bool operator==(std::weak_ptr<yas::ui::node> const &, std::weak_ptr<yas::ui::node> const &);
bool operator!=(std::weak_ptr<yas::ui::node> const &, std::weak_ptr<yas::ui::node> const &);
namespace ui {
    bool operator==(std::weak_ptr<yas::ui::node> const &, std::weak_ptr<yas::ui::node> const &);
    bool operator!=(std::weak_ptr<yas::ui::node> const &, std::weak_ptr<yas::ui::node> const &);
}  // namespace ui
}  // namespace yas
