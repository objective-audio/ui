//
//  yas_ui_node.mm
//

#include "yas_ui_node.h"
#include <cpp_utils/yas_stl_utils.h>
#include <cpp_utils/yas_to_bool.h>
#include <cpp_utils/yas_unless.h>
#include "yas_ui_angle.h"
#include "yas_ui_batch.h"
#include "yas_ui_collider.h"
#include "yas_ui_color.h"
#include "yas_ui_detector.h"
#include "yas_ui_effect.h"
#include "yas_ui_layout_guide.h"
#include "yas_ui_math.h"
#include "yas_ui_matrix.h"
#include "yas_ui_mesh.h"
#include "yas_ui_mesh_data.h"
#include "yas_ui_metal_encode_info.h"
#include "yas_ui_metal_system.h"
#include "yas_ui_render_info.h"
#include "yas_ui_render_target.h"
#include "yas_ui_types.h"

using namespace yas;
using namespace yas::ui;

#pragma mark - node

node::node()
    : _parent(observing::value::holder<std::weak_ptr<node>>::make_shared(std::shared_ptr<node>{nullptr})),
      _renderer(
          observing::value::holder<std::weak_ptr<ui::renderer>>::make_shared(std::shared_ptr<ui::renderer>{nullptr})),
      _position(observing::value::holder<point>::make_shared({.v = 0.0f})),
      _scale(observing::value::holder<size>::make_shared({.v = 1.0f})),
      _angle(observing::value::holder<ui::angle>::make_shared({0.0f})),
      _color(observing::value::holder<ui::color>::make_shared({.v = 1.0f})),
      _alpha(observing::value::holder<float>::make_shared(1.0f)),
      _mesh(observing::value::holder<std::shared_ptr<ui::mesh>>::make_shared(nullptr)),
      _collider(observing::value::holder<std::shared_ptr<ui::collider>>::make_shared(nullptr)),
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

    this->_mesh
        ->observe([this](auto const &) {
            this->_update_mesh_color();
            this->_set_updated(node_update_reason::mesh);
        })
        .sync()
        ->add_to(this->_pool);

    this->_color->observe([this](ui::color const &color) { this->_update_mesh_color(); }).end()->add_to(this->_pool);
    this->_alpha->observe([this](float const &alpha) { this->_update_mesh_color(); }).end()->add_to(this->_pool);

    // collider

    this->_collider->observe([this](auto const &) { this->_set_updated(node_update_reason::collider); })
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

point const &node::position() const {
    return this->_position->value();
}

observing::syncable node::observe_position(observing::caller<point>::handler_f &&handler) {
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

observing::syncable node::observe_angle(observing::caller<ui::angle>::handler_f &&handler) {
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

observing::syncable node::observe_scale(observing::caller<size>::handler_f &&handler) {
    return this->_scale->observe(std::move(handler));
}

void node::set_color(ui::color &&color) {
    this->_color->set_value(std::move(color));
}

void node::set_color(ui::color const &color) {
    this->_color->set_value(color);
}

color const &node::color() const {
    return this->_color->value();
}

observing::syncable node::observe_color(observing::caller<ui::color>::handler_f &&handler) {
    return this->_color->observe(std::move(handler));
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

observing::syncable node::observe_alpha(observing::caller<float>::handler_f &&handler) {
    return this->_alpha->observe(std::move(handler));
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

observing::syncable node::observe_is_enabled(observing::caller<bool>::handler_f &&handler) {
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

void node::set_mesh(std::shared_ptr<ui::mesh> const &mesh) {
    this->_mesh->set_value(mesh);
}

std::shared_ptr<mesh> const &node::mesh() const {
    return this->_mesh->value();
}

observing::syncable node::observe_mesh(observing::caller<std::shared_ptr<ui::mesh>>::handler_f &&handler) {
    return this->_mesh->observe(std::move(handler));
}

void node::set_collider(std::shared_ptr<ui::collider> const &collider) {
    this->_collider->set_value(collider);
}

std::shared_ptr<collider> const &node::collider() const {
    return this->_collider->value();
}

observing::syncable node::observe_collider(observing::caller<std::shared_ptr<ui::collider>>::handler_f &&handler) {
    return this->_collider->observe(std::move(handler));
}

void node::set_batch(std::shared_ptr<ui::batch> const &batch) {
    return this->_batch->set_value(batch);
}

std::shared_ptr<batch> const &node::batch() const {
    return this->_batch->value();
}

observing::syncable node::observe_batch(observing::caller<std::shared_ptr<ui::batch>>::handler_f &&handler) {
    return this->_batch->observe(std::move(handler));
}

void node::set_render_target(std::shared_ptr<ui::render_target> const &render_target) {
    this->_render_target->set_value(render_target);
}

std::shared_ptr<render_target> const &node::render_target() const {
    return this->_render_target->value();
}

observing::syncable node::observe_render_target(
    observing::caller<std::shared_ptr<ui::render_target>>::handler_f &&handler) {
    return this->_render_target->observe(std::move(handler));
}

void node::add_sub_node(std::shared_ptr<node> const &sub_node) {
    sub_node->remove_from_super_node();
    this->_children.emplace_back(sub_node);
    this->_add_sub_node(this->_children.back());
}

void node::add_sub_node(std::shared_ptr<node> const &sub_node, std::size_t const idx) {
    sub_node->remove_from_super_node();
    auto iterator = this->_children.emplace(this->_children.begin() + idx, sub_node);
    this->_add_sub_node(*iterator);
}

void node::remove_from_super_node() {
    if (auto parent = this->_parent->value().lock()) {
        parent->_remove_sub_node(this);
    }
}

std::vector<std::shared_ptr<node>> const &node::children() const {
    return this->_children;
}

std::vector<std::shared_ptr<node>> &node::children() {
    return this->_children;
}

std::shared_ptr<node> node::parent() const {
    return this->_parent->value().lock();
}

std::shared_ptr<renderer> node::renderer() const {
    return this->_renderer->value().lock();
}

observing::endable node::observe(observing::caller<method>::handler_f &&handler) {
    return this->_notifier->observe(std::move(handler));
}

observing::syncable node::observe_parent(observing::caller<std::shared_ptr<node>>::handler_f &&handler) {
    return this->_parent->observe([handler = std::move(handler)](std::weak_ptr<node> const &weak_node) {
        if (auto node = weak_node.lock()) {
            handler(node);
        } else {
            handler(nullptr);
        }
    });
}

point node::convert_position(point const &loc) const {
    auto const loc4 = simd::float4x4(matrix_invert(this->matrix_as_parent())) * to_float4(loc.v);
    return {loc4.x, loc4.y};
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
    if (auto const &mesh = this->_mesh->value()) {
        if (auto ul = unless(metal_object::cast(mesh)->metal_setup(metal_system))) {
            return std::move(ul.value);
        }
    }

    if (auto &render_target = this->_render_target->value()) {
        if (auto ul = unless(metal_object::cast(render_target)->metal_setup(metal_system))) {
            return std::move(ul.value);
        }

        if (auto ul = unless(
                metal_object::cast(renderable_render_target::cast(render_target)->mesh())->metal_setup(metal_system))) {
            return std::move(ul.value);
        }

        if (auto &effect = renderable_render_target::cast(render_target)->effect()) {
            if (auto ul = unless(metal_object::cast(effect)->metal_setup(metal_system))) {
                return std::move(ul.value);
            }
        }
    }

    if (auto &batch = this->_batch->value()) {
        if (auto ul = unless(metal_object::cast(batch)->metal_setup(metal_system))) {
            return std::move(ul.value);
        }
    }

    for (auto &sub_node : this->_children) {
        if (auto ul = unless(metal_object::cast(sub_node)->metal_setup(metal_system))) {
            return std::move(ul.value);
        }
    }

    return setup_metal_result{nullptr};
}

void node::set_renderer(std::shared_ptr<ui::renderer> const &renderer) {
    this->_renderer->set_value(renderer);
}

simd::float4x4 const &node::matrix_as_parent() const {
    return this->matrix();
}

void node::set_parent(std::shared_ptr<node_parent_interface> const &parent) {
    this->_weak_parent = parent;
}

void node::fetch_updates(tree_updates &tree_updates) {
    if (this->_enabled->value()) {
        tree_updates.node_updates.flags |= this->_updates.flags;

        if (auto const &mesh = this->_mesh->value()) {
            tree_updates.mesh_updates.flags |= renderable_mesh::cast(mesh)->updates().flags;

            if (auto const &mesh_data = mesh->mesh_data()) {
                tree_updates.mesh_data_updates.flags |= renderable_mesh_data::cast(mesh_data)->updates().flags;
            }
        }

        if (auto &render_target = this->_render_target->value()) {
            auto const renderable = renderable_render_target::cast(render_target);

            tree_updates.render_target_updates.flags |= renderable->updates().flags;

            auto const &mesh = renderable->mesh();

            tree_updates.mesh_updates.flags |= renderable_mesh::cast(mesh)->updates().flags;

            if (auto &mesh_data = mesh->mesh_data()) {
                tree_updates.mesh_data_updates.flags |= renderable_mesh_data::cast(mesh_data)->updates().flags;
            }

            if (auto &effect = renderable->effect()) {
                tree_updates.effect_updates.flags |= renderable_effect::cast(effect)->updates().flags;
            }
        }

        for (auto &sub_node : this->_children) {
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

        if (auto const &collider = this->_collider->value()) {
            renderable_collider::cast(collider)->set_matrix(this->_matrix);

            if (auto const &detector = render_info.detector) {
                auto const renderer_detector = renderer_detector_interface::cast(detector);
                if (renderer_detector->is_updating()) {
                    renderer_detector->push_front_collider(collider);
                }
            }
        }

        if (auto const &render_encodable = render_info.render_encodable) {
            if (auto const &mesh = this->_mesh->value()) {
                renderable_mesh::cast(mesh)->set_matrix(mesh_matrix);
                render_encodable->append_mesh(mesh);
            }

            if (auto &render_target = this->_render_target->value()) {
                auto const &mesh = renderable_render_target::cast(render_target)->mesh();
                renderable_mesh::cast(mesh)->set_matrix(mesh_matrix);
                render_encodable->append_mesh(mesh);
            }
        }

        if (auto const &render_target = this->_render_target->value()) {
            bool needs_render = this->_updates.test(node_update_reason::render_target);

            if (!needs_render) {
                needs_render = renderable_render_target::cast(render_target)->updates().flags.any();
            }

            auto const renderable = renderable_render_target::cast(render_target);
            auto const &effect = renderable->effect();
            if (!needs_render && effect) {
                needs_render = renderable_effect::cast(effect)->updates().flags.any();
            }

            if (!needs_render) {
                tree_updates tree_updates;

                for (auto &sub_node : this->_children) {
                    renderable_node::cast(sub_node)->fetch_updates(tree_updates);
                }

                needs_render = tree_updates.is_any_updated();
            }

            if (needs_render) {
                auto const &stackable = render_info.render_stackable;

                if (renderable_render_target::cast(render_target)->push_encode_info(stackable)) {
                    ui::render_info target_render_info{.render_encodable = render_info.render_encodable,
                                                       .render_effectable = render_info.render_effectable,
                                                       .render_stackable = render_info.render_stackable,
                                                       .detector = render_info.detector};

                    auto &projection_matrix = renderable->projection_matrix();
                    simd::float4x4 const matrix = projection_matrix * this->_matrix;
                    simd::float4x4 const mesh_matrix = projection_matrix;
                    for (auto &sub_node : this->_children) {
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

            for (auto const &sub_node : this->_children) {
                renderable_node::cast(sub_node)->fetch_updates(tree_updates);
            }

            auto const building_type = tree_updates.batch_building_type();

            ui::render_info batch_render_info{.detector = render_info.detector};
            auto const batch_renderable = renderable_batch::cast(batch);

            if (to_bool(building_type)) {
                batch_render_info.render_encodable = render_encodable::cast(batch);
                batch_renderable->begin_render_meshes_building(building_type);
            }

            for (auto &sub_node : this->_children) {
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
            for (auto const &sub_node : this->_children) {
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

    for (auto &sub_node : this->_children) {
        if (renderable_node::cast(sub_node)->is_rendering_color_exists()) {
            return true;
        }
    }

    if (auto const &mesh = this->_mesh->value()) {
        return renderable_mesh::cast(mesh)->is_rendering_color_exists();
    }

    return false;
}

void node::clear_updates() {
    if (this->_enabled->value()) {
        this->_updates.flags.reset();

        if (auto const &mesh = this->_mesh->value()) {
            renderable_mesh::cast(mesh)->clear_updates();
        }

        if (auto &render_target = this->_render_target->value()) {
            renderable_render_target::cast(render_target)->clear_updates();
        }

        for (auto &sub_node : this->_children) {
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
    sub_node->_set_renderer_recursively(this->_renderer->value().lock());

    sub_node->_notifier->notify(method::added_to_super);

    this->_set_updated(node_update_reason::children);
}

void node::_remove_sub_node(node *sub_node) {
    std::weak_ptr<node> weak_node = std::shared_ptr<node>{nullptr};
    sub_node->_parent->set_value(std::move(weak_node));
    sub_node->_weak_parent.reset();
    sub_node->_set_renderer_recursively(nullptr);

    erase_if(this->_children, [&sub_node](std::shared_ptr<node> const &node) { return node.get() == sub_node; });

    sub_node->_notifier->notify(method::removed_from_super);

    this->_set_updated(node_update_reason::children);
}

void node::_remove_sub_nodes_on_destructor() {
    for (auto const &sub_node : this->_children) {
        std::weak_ptr<node> weak_node = std::shared_ptr<node>{nullptr};
        sub_node->_parent->set_value(std::move(weak_node));
        sub_node->_weak_parent.reset();
        sub_node->_set_renderer_recursively(nullptr);
        sub_node->_notifier->notify(method::removed_from_super);
    }
}

void node::_set_renderer_recursively(std::shared_ptr<ui::renderer> const &renderer) {
    this->_renderer->set_value(renderer);

    for (auto const &sub_node : this->_children) {
        sub_node->_set_renderer_recursively(renderer);
    }
}

void node::_update_mesh_color() {
    if (auto const &mesh = this->_mesh->value()) {
        auto const &color = this->_color->value();
        auto const &alpha = this->_alpha->value();
        mesh->set_color({color.red, color.green, color.blue, alpha});
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
    auto shared = std::shared_ptr<node>(new node{});
    shared->_weak_node = shared;
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
