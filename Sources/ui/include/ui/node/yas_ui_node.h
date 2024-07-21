//
//  yas_ui_node.h
//

#pragma once

#include <ui/action/yas_ui_action_dependency.h>
#include <ui/collider/yas_ui_collider.h>
#include <ui/layout/yas_ui_layout_dependency.h>
#include <ui/mesh/yas_ui_mesh.h>
#include <ui/metal/yas_ui_metal_setup_types.h>
#include <ui/node/yas_ui_node_action_dependency.h>
#include <ui/node/yas_ui_node_dependency.h>
#include <ui/renderer/yas_ui_renderer.h>
#include <ui/renderer/yas_ui_renderer_dependency.h>

#include <observing/umbrella.hpp>
#include <vector>

namespace yas::ui {
struct node final : renderable_node,
                    layout_point_target,
                    parent_for_node,
                    translate_action_target,
                    rotate_action_target,
                    scale_action_target,
                    color_action_target,
                    alpha_action_target {
    enum class method {
        added_to_super,
        removed_from_super,
    };

    virtual ~node();

    void set_position(ui::point &&) override;
    void set_position(ui::point const &);
    void set_x(float const);
    void set_y(float const);
    [[nodiscard]] ui::point const &position() const;
    [[nodiscard]] observing::syncable observe_position(std::function<void(ui::point const &)> &&);

    void set_angle(ui::angle &&) override;
    void set_angle(ui::angle const &);
    [[nodiscard]] ui::angle const &angle() const;
    [[nodiscard]] observing::syncable observe_angle(std::function<void(ui::angle const &)> &&);

    void set_scale(ui::size &&) override;
    void set_scale(ui::size const &);
    void set_width(float const);
    void set_height(float const);
    [[nodiscard]] ui::size const &scale() const;
    [[nodiscard]] observing::syncable observe_scale(std::function<void(ui::size const &)> &&);

    void set_rgb_color(ui::rgb_color &&) override;
    void set_rgb_color(ui::rgb_color const &);
    [[nodiscard]] ui::rgb_color const &rgb_color() const;
    [[nodiscard]] observing::syncable observe_rgb_color(std::function<void(ui::rgb_color const &)> &&);

    void set_alpha(float &&) override;
    void set_alpha(float const &);
    [[nodiscard]] float const &alpha() const;
    [[nodiscard]] observing::syncable observe_alpha(std::function<void(float const &)> &&);

    void set_color(ui::color &&);
    void set_color(ui::color const &);
    [[nodiscard]] ui::color color() const;

    void set_is_enabled(bool &&);
    void set_is_enabled(bool const &);
    [[nodiscard]] bool const &is_enabled() const;
    [[nodiscard]] observing::syncable observe_is_enabled(std::function<void(bool const &)> &&);

    [[nodiscard]] simd::float4x4 const &matrix() const;
    [[nodiscard]] simd::float4x4 const &local_matrix() const;

    void set_meshes(std::vector<std::shared_ptr<mesh>> const &);
    void push_back_mesh(std::shared_ptr<mesh> const &);
    void insert_mesh_at(std::shared_ptr<mesh> const &, std::size_t const);
    void erase_mesh_at(std::size_t const);
    [[nodiscard]] std::vector<std::shared_ptr<mesh>> const &meshes() const;

    using meshes_event = observing::vector::holder<std::shared_ptr<ui::mesh>>::event;
    [[nodiscard]] observing::syncable observe_meshes(std::function<void(meshes_event const &)> &&);

    void set_colliders(std::vector<std::shared_ptr<ui::collider>> const &);
    void push_back_collider(std::shared_ptr<ui::collider> const &);
    void insert_collider_at(std::shared_ptr<ui::collider> const &, std::size_t const);
    void erase_collider_at(std::size_t const);
    [[nodiscard]] std::vector<std::shared_ptr<ui::collider>> const &colliders() const;

    using colliders_event = observing::vector::holder<std::shared_ptr<ui::collider>>::event;
    [[nodiscard]] observing::syncable observe_colliders(std::function<void(colliders_event const &)> &&);

    void set_batch(std::shared_ptr<batch> const &);
    [[nodiscard]] std::shared_ptr<batch> const &batch() const;
    [[nodiscard]] observing::syncable observe_batch(std::function<void(std::shared_ptr<ui::batch> const &)> &&);

    void set_render_target(std::shared_ptr<render_target> const &);
    [[nodiscard]] std::shared_ptr<render_target> const &render_target() const;
    [[nodiscard]] observing::syncable observe_render_target(
        std::function<void(std::shared_ptr<ui::render_target> const &)> &&);

    void add_sub_node(std::shared_ptr<node> const &);
    void add_sub_node(std::shared_ptr<node> const &, std::size_t const);
    void remove_sub_node(std::size_t const);
    void remove_all_sub_nodes();
    void remove_from_super_node();

    [[nodiscard]] [[deprecated]] std::vector<std::shared_ptr<node>> const &children() const;
    [[nodiscard]] std::vector<std::shared_ptr<node>> const &sub_nodes() const;
    [[nodiscard]] std::shared_ptr<node> parent() const;

    [[nodiscard]] observing::endable observe(std::function<void(method const &)> &&);

    [[nodiscard]] ui::point convert_position(ui::point const &) const;

    void attach_x_layout_guide(ui::layout_value_guide &);
    void attach_y_layout_guide(ui::layout_value_guide &);
    void attach_position_layout_guides(ui::layout_point_guide &);

    ui::setup_metal_result metal_setup(std::shared_ptr<ui::metal_system> const &);

    [[nodiscard]] static std::shared_ptr<node> make_shared();
    [[nodiscard]] static std::shared_ptr<node> make_shared(std::shared_ptr<parent_for_node> const &);

   private:
    std::weak_ptr<node> _weak_node;
    std::weak_ptr<parent_for_node> _weak_parent;

    observing::value::holder_ptr<std::weak_ptr<node>> const _parent;

    observing::value::holder_ptr<ui::point> const _position;
    observing::value::holder_ptr<ui::angle> const _angle;
    observing::value::holder_ptr<ui::size> const _scale;
    observing::value::holder_ptr<ui::rgb_color> const _rgb_color;
    observing::value::holder_ptr<float> const _alpha;
    observing::vector::holder_ptr<std::shared_ptr<ui::mesh>> const _meshes;
    observing::vector::holder_ptr<std::shared_ptr<ui::collider>> const _colliders;
    observing::value::holder_ptr<std::shared_ptr<ui::batch>> const _batch;
    observing::value::holder_ptr<std::shared_ptr<ui::render_target>> const _render_target;
    observing::value::holder_ptr<bool> const _enabled;

    observing::canceller_pool _pool;
    observing::cancellable_ptr _x_canceller = nullptr;
    observing::cancellable_ptr _y_canceller = nullptr;
    observing::cancellable_ptr _position_canceller = nullptr;

    std::vector<std::shared_ptr<node>> _sub_nodes;

    mutable simd::float4x4 _matrix = matrix_identity_float4x4;
    mutable simd::float4x4 _local_matrix = matrix_identity_float4x4;

    observing::notifier_ptr<ui::node::method> const _notifier = observing::notifier<ui::node::method>::make_shared();

    node_updates_t _updates;

    node();

    node(node const &) = delete;
    node(node &&) = delete;
    node &operator=(node const &) = delete;
    node &operator=(node &&) = delete;

    simd::float4x4 const &matrix_as_parent() const override;

    void fetch_updates(ui::tree_updates &) override;
    void build_render_info(ui::render_info &) override;
    bool is_rendering_color_exists() override;
    void clear_updates() override;

    void set_layout_point(ui::point const &) override;

    void _add_sub_node(std::shared_ptr<node> &sub_node);
    void _remove_sub_node(ui::node *sub_node);
    void _remove_sub_nodes_on_destructor();
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
