//
//  yas_ui_node.mm
//

#include "yas_ui_node.h"
#include <cpp_utils/yas_to_bool.h>
#include <cpp_utils/yas_unless.h>
#include <ui/yas_ui_angle.h>
#include <ui/yas_ui_batch.h>
#include <ui/yas_ui_matrix.h>
#include <ui/yas_ui_mesh.h>
#include <ui/yas_ui_mesh_data.h>
#include <ui/yas_ui_render_info.h>
#include <ui/yas_ui_render_target.h>
#include <ui/yas_ui_rgb_color.h>

using namespace yas;
using namespace yas::ui;

#pragma mark - node

node::node()
    : _parent(observing::value::holder<std::weak_ptr<node>>::make_shared(std::shared_ptr<node>{nullptr})),
      _position(observing::value::holder<point>::make_shared({.v = 0.0f})),
      _scale(observing::value::holder<size>::make_shared({.v = 1.0f})),
      _angle(observing::value::holder<ui::angle>::make_shared({0.0f})),
      _rgb_color(observing::value::holder<ui::rgb_color>::make_shared({.v = 1.0f})),
      _alpha(observing::value::holder<float>::make_shared(1.0f)),
      _meshes(observing::vector::holder<std::shared_ptr<ui::mesh>>::make_shared()),
      _colliders(observing::vector::holder<std::shared_ptr<ui::collider>>::make_shared()),
      _batch(observing::value::holder<std::shared_ptr<ui::batch>>::make_shared(std::shared_ptr<ui::batch>{nullptr})),
      _render_target(observing::value::holder<std::shared_ptr<ui::render_target>>::make_shared(nullptr)),
      _enabled(observing::value::holder<bool>::make_shared(true)) {
    // enabled

    this->_enabled->observe([this](bool const &) { this->_set_updated(node_update_reason::enabled); })
        .end()
        ->add_to(this->_pool);

    // geometry

    this->_position->observe([this](auto const &) { this->_set_updated(node_update_reason::geometry); })
        .end()
        ->add_to(this->_pool);
    this->_angle->observe([this](auto const &) { this->_set_updated(node_update_reason::geometry); })
        .end()
        ->add_to(this->_pool);
    this->_scale->observe([this](auto const &) { this->_set_updated(node_update_reason::geometry); })
        .end()
        ->add_to(this->_pool);

    // mesh and mesh_color

    this->_meshes
        ->observe([this](auto const &) {
            this->_update_mesh_color();
            this->_set_updated(node_update_reason::mesh);
        })
        .sync()
        ->add_to(this->_pool);

    this->_rgb_color->observe([this](ui::rgb_color const &color) { this->_update_mesh_color(); })
        .end()
        ->add_to(this->_pool);
    this->_alpha->observe([this](float const &alpha) { this->_update_mesh_color(); }).end()->add_to(this->_pool);

    // collider

    this->_colliders->observe([this](auto const &) { this->_set_updated(node_update_reason::collider); })
        .end()
        ->add_to(this->_pool);

    // batch

    this->_batch
        ->observe(
            [this, prev_batch = std::shared_ptr<ui::batch>{nullptr}](std::shared_ptr<ui::batch> const &batch) mutable {
                if (prev_batch) {
                    renderable_batch::cast(prev_batch)->clear_render_meshes();
                }

                if (batch) {
                    renderable_batch::cast(batch)->clear_render_meshes();
                }

                prev_batch = batch;

                this->_set_updated(node_update_reason::batch);
            })
        .end()
        ->add_to(this->_pool);

    // render_target

    this->_render_target->observe([this](auto const &) { this->_set_updated(node_update_reason::render_target); })
        .end()
        ->add_to(this->_pool);
}

node::~node() {
    this->_remove_sub_nodes_on_destructor();
}

void node::set_position(point &&position) {
    this->_position->set_value(std::move(position));
}

void node::set_position(point const &position) {
    this->_position->set_value(position);
}

void node::set_x(float const x) {
    this->set_position({.x = x, .y = this->_position->value().y});
}

void node::set_y(float const y) {
    this->set_position({.x = this->_position->value().x, .y = y});
}

point const &node::position() const {
    return this->_position->value();
}

observing::syncable node::observe_position(std::function<void(point const &)> &&handler) {
    return this->_position->observe(std::move(handler));
}

void node::set_angle(ui::angle &&angle) {
    this->_angle->set_value(std::move(angle));
}

void node::set_angle(ui::angle const &angle) {
    this->_angle->set_value(angle);
}

angle const &node::angle() const {
    return this->_angle->value();
}

observing::syncable node::observe_angle(std::function<void(ui::angle const &)> &&handler) {
    return this->_angle->observe(std::move(handler));
}

void node::set_scale(size &&scale) {
    this->_scale->set_value(std::move(scale));
}

void node::set_scale(size const &scale) {
    this->_scale->set_value(scale);
}

size const &node::scale() const {
    return this->_scale->value();
}

observing::syncable node::observe_scale(std::function<void(size const &)> &&handler) {
    return this->_scale->observe(std::move(handler));
}

void node::set_rgb_color(ui::rgb_color &&color) {
    this->_rgb_color->set_value(std::move(color));
}

void node::set_rgb_color(ui::rgb_color const &color) {
    this->_rgb_color->set_value(color);
}

rgb_color const &node::rgb_color() const {
    return this->_rgb_color->value();
}

observing::syncable node::observe_rgb_color(std::function<void(ui::rgb_color const &)> &&handler) {
    return this->_rgb_color->observe(std::move(handler));
}

void node::set_alpha(float &&alpha) {
    this->_alpha->set_value(std::move(alpha));
}

void node::set_alpha(float const &alpha) {
    this->_alpha->set_value(alpha);
}

float const &node::alpha() const {
    return this->_alpha->value();
}

observing::syncable node::observe_alpha(std::function<void(float const &)> &&handler) {
    return this->_alpha->observe(std::move(handler));
}

void node::set_color(ui::color &&color) {
    this->set_rgb_color(std::move(color.rgb));
    this->set_alpha(std::move(color.alpha));
}

void node::set_color(ui::color const &color) {
    this->set_rgb_color(color.rgb);
    this->set_alpha(color.alpha);
}

ui::color node::color() const {
    auto const &rgb = this->rgb_color();
    return {rgb.red, rgb.green, rgb.blue, this->alpha()};
}

void node::set_is_enabled(bool &&is_enabled) {
    this->_enabled->set_value(std::move(is_enabled));
}

void node::set_is_enabled(bool const &is_enabled) {
    this->_enabled->set_value(is_enabled);
}

bool const &node::is_enabled() const {
    return this->_enabled->value();
}

observing::syncable node::observe_is_enabled(std::function<void(bool const &)> &&handler) {
    return this->_enabled->observe(std::move(handler));
}

simd::float4x4 const &node::matrix() const {
    this->_update_matrix();
    return this->_matrix;
}

simd::float4x4 const &node::local_matrix() const {
    this->_update_local_matrix();
    return this->_local_matrix;
}

void node::set_meshes(std::vector<std::shared_ptr<mesh>> const &meshes) {
    this->_meshes->replace(meshes);
}

void node::push_back_mesh(std::shared_ptr<mesh> const &mesh) {
    this->_meshes->push_back(mesh);
}

void node::insert_mesh_at(std::shared_ptr<mesh> const &mesh, std::size_t const idx) {
    this->_meshes->insert(mesh, idx);
}

void node::erase_mesh_at(std::size_t const idx) {
    this->_meshes->erase(idx);
}

std::vector<std::shared_ptr<mesh>> const &node::meshes() const {
    return this->_meshes->value();
}

observing::syncable node::observe_meshes(std::function<void(meshes_event const &)> &&handler) {
    return this->_meshes->observe(std::move(handler));
}

void node::set_colliders(std::vector<std::shared_ptr<ui::collider>> const &colliders) {
    this->_colliders->replace(colliders);
}

void node::push_back_collider(std::shared_ptr<ui::collider> const &collider) {
    this->_colliders->push_back(collider);
}

void node::insert_collider_at(std::shared_ptr<ui::collider> const &collider, std::size_t const idx) {
    this->_colliders->insert(collider, idx);
}

void node::erase_collider_at(std::size_t const idx) {
    this->_colliders->erase(idx);
}

std::vector<std::shared_ptr<ui::collider>> const &node::colliders() const {
    return this->_colliders->value();
}

observing::syncable node::observe_colliders(std::function<void(colliders_event const &)> &&handler) {
    return this->_colliders->observe(std::move(handler));
}

void node::set_batch(std::shared_ptr<ui::batch> const &batch) {
    return this->_batch->set_value(batch);
}

std::shared_ptr<batch> const &node::batch() const {
    return this->_batch->value();
}

observing::syncable node::observe_batch(std::function<void(std::shared_ptr<ui::batch> const &)> &&handler) {
    return this->_batch->observe(std::move(handler));
}

void node::set_render_target(std::shared_ptr<ui::render_target> const &render_target) {
    this->_render_target->set_value(render_target);
}

std::shared_ptr<render_target> const &node::render_target() const {
    return this->_render_target->value();
}

observing::syncable node::observe_render_target(
    std::function<void(std::shared_ptr<ui::render_target> const &)> &&handler) {
    return this->_render_target->observe(std::move(handler));
}

void node::add_sub_node(std::shared_ptr<node> const &sub_node) {
    sub_node->remove_from_super_node();
    this->_sub_nodes.emplace_back(sub_node);
    this->_add_sub_node(this->_sub_nodes.back());
}

void node::add_sub_node(std::shared_ptr<node> const &sub_node, std::size_t const idx) {
    sub_node->remove_from_super_node();
    auto iterator = this->_sub_nodes.emplace(this->_sub_nodes.begin() + idx, sub_node);
    this->_add_sub_node(*iterator);
}

void node::remove_sub_node(std::size_t const idx) {
    if (idx < this->_sub_nodes.size()) {
        this->_sub_nodes.at(idx)->remove_from_super_node();
    }
}

void node::remove_all_sub_nodes() {
    if (this->_sub_nodes.size() == 0) {
        return;
    }

    std::weak_ptr<node> weak_node = std::shared_ptr<node>{nullptr};

    for (auto const &sub_node : this->_sub_nodes) {
        sub_node->_parent->set_value(std::move(weak_node));
        sub_node->_weak_parent.reset();
    }

    auto const sub_nodes = std::move(this->_sub_nodes);
    this->_sub_nodes.clear();

    for (auto const &sub_node : sub_nodes) {
        sub_node->_notifier->notify(method::removed_from_super);
    }

    this->_set_updated(node_update_reason::children);
}

void node::remove_from_super_node() {
    if (auto parent = this->_parent->value().lock()) {
        parent->_remove_sub_node(this);
    }
}

std::vector<std::shared_ptr<node>> const &node::children() const {
    return this->_sub_nodes;
}

std::vector<std::shared_ptr<node>> const &node::sub_nodes() const {
    return this->_sub_nodes;
}

std::shared_ptr<node> node::parent() const {
    return this->_parent->value().lock();
}

observing::endable node::observe(std::function<void(method const &)> &&handler) {
    return this->_notifier->observe(std::move(handler));
}

point node::convert_position(point const &loc) const {
    return this->convert_position_as_parent(loc);
}

void node::attach_x_layout_guide(layout_value_guide &guide) {
    this->_x_canceller =
        guide.observe([this](float const &x) {
                 this->_position->set_value(point{x, this->position().y});
             })
            .sync();

    this->_position_canceller = nullptr;
}

void node::attach_y_layout_guide(layout_value_guide &guide) {
    this->_y_canceller =
        guide.observe([this](float const &y) {
                 this->_position->set_value(point{this->position().x, y});
             })
            .sync();

    this->_position_canceller = nullptr;
}

void node::attach_position_layout_guides(layout_point_guide &guide_point) {
    this->_position_canceller =
        guide_point.observe([this](auto const &position) { this->_position->set_value(position); }).sync();

    this->_x_canceller = nullptr;
    this->_y_canceller = nullptr;
}

setup_metal_result node::metal_setup(std::shared_ptr<metal_system> const &metal_system) {
    for (auto const &mesh : this->_meshes->value()) {
        if (auto ul = unless(mesh->metal_setup(metal_system))) {
            return std::move(ul.value);
        }
    }

    if (auto &render_target = this->_render_target->value()) {
        if (auto ul = unless(render_target->metal_setup(metal_system))) {
            return std::move(ul.value);
        }

        if (auto ul = unless(render_target->mesh()->metal_setup(metal_system))) {
            return std::move(ul.value);
        }

        if (auto &effect = render_target->effect()) {
            if (auto ul = unless(effect->metal_setup(metal_system))) {
                return std::move(ul.value);
            }
        }
    }

    if (auto &batch = this->_batch->value()) {
        if (auto ul = unless(batch->metal_setup(metal_system))) {
            return std::move(ul.value);
        }
    }

    for (auto &sub_node : this->_sub_nodes) {
        if (auto ul = unless(sub_node->metal_setup(metal_system))) {
            return std::move(ul.value);
        }
    }

    return setup_metal_result{nullptr};
}

simd::float4x4 const &node::matrix_as_parent() const {
    return this->matrix();
}

void node::fetch_updates(tree_updates &tree_updates) {
    if (this->_enabled->value()) {
        tree_updates.node_updates.flags |= this->_updates.flags;

        for (auto const &mesh : this->_meshes->value()) {
            tree_updates.mesh_updates.flags |= renderable_mesh::cast(mesh)->updates().flags;

            if (auto const &vertex_data = mesh->vertex_data()) {
                tree_updates.vertex_data_updates.flags |= vertex_data->updates().flags;
            }

            if (auto const &index_data = mesh->index_data()) {
                tree_updates.index_data_updates.flags |= index_data->updates().flags;
            }
        }

        if (auto &render_target = this->_render_target->value()) {
            auto const renderable = render_target;

            tree_updates.render_target_updates.flags |= renderable->updates().flags;

            auto const &mesh = renderable->mesh();

            tree_updates.mesh_updates.flags |= renderable_mesh::cast(mesh)->updates().flags;

            if (auto const &vertex_data = mesh->vertex_data()) {
                tree_updates.vertex_data_updates.flags |= vertex_data->updates().flags;
            }

            if (auto const &index_data = mesh->index_data()) {
                tree_updates.index_data_updates.flags |= index_data->updates().flags;
            }

            if (auto &effect = renderable->effect()) {
                tree_updates.effect_updates.flags |= renderable_effect::cast(effect)->updates().flags;
            }
        }

        for (auto &sub_node : this->_sub_nodes) {
            renderable_node::cast(sub_node)->fetch_updates(tree_updates);
        }
    } else if (this->_updates.test(node_update_reason::enabled)) {
        tree_updates.node_updates.set(node_update_reason::enabled);
    }
}

void node::build_render_info(render_info &render_info) {
    if (this->_enabled->value()) {
        this->_update_local_matrix();

        this->_matrix = render_info.matrix * this->_local_matrix;
        auto const mesh_matrix = render_info.mesh_matrix * this->_local_matrix;

        if (this->_colliders->size() > 0) {
            for (auto const &collider : this->_colliders->value()) {
                renderable_collider::cast(collider)->set_matrix(this->_matrix);
            }

            if (auto const &detector = render_info.detector) {
                if (detector->is_updating()) {
                    for (auto const &collider : this->_colliders->value()) {
                        detector->push_front_collider(collider);
                    }
                }
            }
        }

        if (auto const &render_encodable = render_info.render_encodable) {
            for (auto const &mesh : this->_meshes->value()) {
                renderable_mesh::cast(mesh)->set_matrix(mesh_matrix);
                render_encodable->append_mesh(mesh);
            }

            if (auto &render_target = this->_render_target->value()) {
                auto const &mesh = render_target->mesh();
                renderable_mesh::cast(mesh)->set_matrix(mesh_matrix);
                render_encodable->append_mesh(mesh);
            }
        }

        if (auto const &render_target = this->_render_target->value()) {
            bool needs_render = this->_updates.test(node_update_reason::render_target);

            if (!needs_render) {
                needs_render = render_target->updates().flags.any();
            }

            auto const renderable = render_target;
            auto const &effect = renderable->effect();
            if (!needs_render && effect) {
                needs_render = renderable_effect::cast(effect)->updates().flags.any();
            }

            if (!needs_render) {
                tree_updates tree_updates;

                for (auto &sub_node : this->_sub_nodes) {
                    renderable_node::cast(sub_node)->fetch_updates(tree_updates);
                }

                needs_render = tree_updates.is_any_updated();
            }

            if (needs_render) {
                auto const &stackable = render_info.render_stackable;

                if (render_target->push_encode_info(stackable)) {
                    ui::render_info target_render_info{.render_encodable = render_info.render_encodable,
                                                       .render_effectable = render_info.render_effectable,
                                                       .render_stackable = render_info.render_stackable,
                                                       .detector = render_info.detector};

                    auto &projection_matrix = renderable->projection_matrix();
                    simd::float4x4 const matrix = projection_matrix * this->_matrix;
                    simd::float4x4 const mesh_matrix = projection_matrix;
                    for (auto &sub_node : this->_sub_nodes) {
                        target_render_info.matrix = matrix;
                        target_render_info.mesh_matrix = mesh_matrix;
                        sub_node->build_render_info(target_render_info);
                    }

                    if (effect) {
                        render_info.render_effectable->append_effect(effect);
                    }

                    stackable->pop_encode_info();
                }
            }
        } else if (auto const &batch = _batch->value()) {
            tree_updates tree_updates;

            for (auto const &sub_node : this->_sub_nodes) {
                renderable_node::cast(sub_node)->fetch_updates(tree_updates);
            }

            if (this->_updates.test(node_update_reason::children)) {
                tree_updates.node_updates.set(node_update_reason::children);
            }

            auto const building_type = tree_updates.batch_building_type();

            ui::render_info batch_render_info{.detector = render_info.detector};
            auto const batch_renderable = renderable_batch::cast(batch);

            if (to_bool(building_type)) {
                batch_render_info.render_encodable = render_encodable::cast(batch);
                batch_renderable->begin_render_meshes_building(building_type);
            }

            for (auto &sub_node : this->_sub_nodes) {
                batch_render_info.matrix = this->_matrix;
                batch_render_info.mesh_matrix = matrix_identity_float4x4;
                sub_node->build_render_info(batch_render_info);
            }

            if (to_bool(building_type)) {
                batch_renderable->commit_render_meshes_building();
            }

            for (auto const &mesh : batch_renderable->meshes()) {
                renderable_mesh::cast(mesh)->set_matrix(mesh_matrix);
                render_info.render_encodable->append_mesh(mesh);
            }
        } else {
            for (auto const &sub_node : this->_sub_nodes) {
                render_info.matrix = this->_matrix;
                render_info.mesh_matrix = mesh_matrix;
                sub_node->build_render_info(render_info);
            }
        }
    }
}

bool node::is_rendering_color_exists() {
    if (!this->_enabled->value()) {
        return false;
    }

    for (auto &sub_node : this->_sub_nodes) {
        if (renderable_node::cast(sub_node)->is_rendering_color_exists()) {
            return true;
        }
    }

    for (auto const &mesh : this->_meshes->value()) {
        if (renderable_mesh::cast(mesh)->is_rendering_color_exists()) {
            return true;
        }
    }

    return false;
}

void node::clear_updates() {
    if (this->_enabled->value()) {
        this->_updates.flags.reset();

        for (auto const &mesh : this->_meshes->value()) {
            renderable_mesh::cast(mesh)->clear_updates();
        }

        if (auto &render_target = this->_render_target->value()) {
            render_target->clear_updates();
        }

        for (auto &sub_node : this->_sub_nodes) {
            renderable_node::cast(sub_node)->clear_updates();
        }
    } else {
        this->_updates.reset(node_update_reason::enabled);
    }
}

void node::set_layout_point(ui::point const &point) {
    this->set_position(point);
}

void node::_add_sub_node(std::shared_ptr<node> &sub_node) {
    sub_node->_parent->set_value(this->_weak_node);
    sub_node->_weak_parent = this->_weak_node;

    sub_node->_notifier->notify(method::added_to_super);

    this->_set_updated(node_update_reason::children);
}

void node::_remove_sub_node(node *sub_node) {
    std::weak_ptr<node> weak_node = std::shared_ptr<node>{nullptr};
    sub_node->_parent->set_value(std::move(weak_node));
    sub_node->_weak_parent.reset();

    std::erase_if(this->_sub_nodes, [&sub_node](std::shared_ptr<node> const &node) { return node.get() == sub_node; });

    sub_node->_notifier->notify(method::removed_from_super);

    this->_set_updated(node_update_reason::children);
}

void node::_remove_sub_nodes_on_destructor() {
    for (auto const &sub_node : this->_sub_nodes) {
        std::weak_ptr<node> weak_node = std::shared_ptr<node>{nullptr};
        sub_node->_parent->set_value(std::move(weak_node));
        sub_node->_weak_parent.reset();
        sub_node->_notifier->notify(method::removed_from_super);
    }
}

void node::_update_mesh_color() {
    for (auto const &mesh : this->_meshes->value()) {
        mesh->set_color(this->color());
    }
}

void node::_set_updated(node_update_reason const reason) {
    this->_updates.set(reason);
}

void node::_update_local_matrix() const {
    if (this->_updates.test(node_update_reason::geometry)) {
        auto const &position = this->_position->value();
        auto const &angle = this->_angle->value();
        auto const &scale = this->_scale->value();
        this->_local_matrix = matrix::translation(position.x, position.y) * matrix::rotation(angle.degrees) *
                              matrix::scale(scale.width, scale.height);
    }
}

void node::_update_matrix() const {
    simd::float4x4 parent_matrix = matrix_identity_float4x4;

    if (auto locked_parent = this->_weak_parent.lock()) {
        parent_matrix = locked_parent->matrix_as_parent();
    }

    this->_update_local_matrix();

    this->_matrix = parent_matrix * this->_local_matrix;
}

std::shared_ptr<node> node::make_shared() {
    return make_shared(nullptr);
}

std::shared_ptr<node> node::make_shared(std::shared_ptr<parent_for_node> const &parent) {
    auto shared = std::shared_ptr<node>(new node{});
    shared->_weak_node = shared;
    shared->_weak_parent = parent;
    return shared;
}

std::string yas::to_string(node::method const &method) {
    switch (method) {
        case node::method::added_to_super:
            return "added_to_super";
        case node::method::removed_from_super:
            return "removed_from_super";
    }
}

std::ostream &operator<<(std::ostream &os, yas::ui::node::method const &method) {
    os << to_string(method);
    return os;
}

bool yas::operator==(std::weak_ptr<yas::ui::node> const &lhs, std::weak_ptr<yas::ui::node> const &rhs) {
    auto locked_lhs = lhs.lock();
    auto locked_rhs = rhs.lock();
    return (locked_lhs && locked_rhs && locked_lhs == locked_rhs);
}

bool yas::operator!=(std::weak_ptr<yas::ui::node> const &lhs, std::weak_ptr<yas::ui::node> const &rhs) {
    auto locked_lhs = lhs.lock();
    auto locked_rhs = rhs.lock();
    return (!locked_lhs || !locked_rhs || locked_lhs != locked_rhs);
}

bool yas::ui::operator==(std::weak_ptr<yas::ui::node> const &lhs, std::weak_ptr<yas::ui::node> const &rhs) {
    auto locked_lhs = lhs.lock();
    auto locked_rhs = rhs.lock();
    return (locked_lhs && locked_rhs && locked_lhs == locked_rhs);
}

bool yas::ui::operator!=(std::weak_ptr<yas::ui::node> const &lhs, std::weak_ptr<yas::ui::node> const &rhs) {
    auto locked_lhs = lhs.lock();
    auto locked_rhs = rhs.lock();
    return (!locked_lhs || !locked_rhs || locked_lhs != locked_rhs);
}
