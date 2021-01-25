//
//  yas_ui_node.mm
//

#include "yas_ui_node.h"
#include <cpp_utils/yas_stl_utils.h>
#include <cpp_utils/yas_to_bool.h>
#include <cpp_utils/yas_unless.h>
#include "yas_ui_angle.h"
#include "yas_ui_batch.h"
#include "yas_ui_batch_protocol.h"
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

#pragma mark - node

ui::node::node()
    : _parent(observing::value::holder<ui::node_wptr>::make_shared(ui::node_ptr{nullptr})),
      _renderer(observing::value::holder<ui::renderer_wptr>::make_shared(ui::renderer_ptr{nullptr})),
      _position(observing::value::holder<ui::point>::make_shared({.v = 0.0f})),
      _scale(observing::value::holder<ui::size>::make_shared({.v = 1.0f})),
      _angle(observing::value::holder<ui::angle>::make_shared({0.0f})),
      _color(observing::value::holder<ui::color>::make_shared({.v = 1.0f})),
      _alpha(observing::value::holder<float>::make_shared(1.0f)),
      _mesh(observing::value::holder<ui::mesh_ptr>::make_shared(nullptr)),
      _collider(observing::value::holder<ui::collider_ptr>::make_shared(nullptr)),
      _batch(observing::value::holder<std::shared_ptr<ui::batch>>::make_shared(std::shared_ptr<ui::batch>{nullptr})),
      _render_target(observing::value::holder<ui::render_target_ptr>::make_shared(nullptr)),
      _enabled(observing::value::holder<bool>::make_shared(true)) {
}

ui::node::~node() = default;

observing::value::holder_ptr<ui::point> const &ui::node::position() const {
    return this->_position;
}

observing::value::holder_ptr<ui::angle> const &ui::node::angle() const {
    return this->_angle;
}

observing::value::holder_ptr<ui::size> const &ui::node::scale() const {
    return this->_scale;
}

observing::value::holder_ptr<ui::color> const &ui::node::color() const {
    return this->_color;
}

observing::value::holder_ptr<float> const &ui::node::alpha() const {
    return this->_alpha;
}

observing::value::holder_ptr<bool> const &ui::node::is_enabled() const {
    return this->_enabled;
}

simd::float4x4 const &ui::node::matrix() const {
    this->_update_matrix();
    return this->_matrix;
}

simd::float4x4 const &ui::node::local_matrix() const {
    this->_update_local_matrix();
    return this->_local_matrix;
}

observing::value::holder_ptr<ui::mesh_ptr> const &ui::node::mesh() const {
    return this->_mesh;
}

observing::value::holder_ptr<ui::collider_ptr> const &ui::node::collider() const {
    return this->_collider;
}

observing::value::holder_ptr<std::shared_ptr<ui::batch>> const &ui::node::batch() const {
    return this->_batch;
}

observing::value::holder_ptr<ui::render_target_ptr> const &ui::node::render_target() const {
    return this->_render_target;
}

void ui::node::add_sub_node(ui::node_ptr const &sub_node) {
    sub_node->remove_from_super_node();
    this->_children.emplace_back(sub_node);
    this->_add_sub_node(this->_children.back(), this->_weak_node.lock());
}

void ui::node::add_sub_node(ui::node_ptr const &sub_node, std::size_t const idx) {
    sub_node->remove_from_super_node();
    auto iterator = this->_children.emplace(this->_children.begin() + idx, sub_node);
    this->_add_sub_node(*iterator, this->_weak_node.lock());
}

void ui::node::remove_from_super_node() {
    if (auto parent = this->_parent->value().lock()) {
        parent->_remove_sub_node(this->_weak_node.lock());
    }
}

std::vector<ui::node_ptr> const &ui::node::children() const {
    return this->_children;
}

std::vector<ui::node_ptr> &ui::node::children() {
    return this->_children;
}

ui::node_ptr ui::node::parent() const {
    return this->_parent->value().lock();
}

ui::renderer_ptr ui::node::renderer() const {
    return this->_renderer->value().lock();
}

observing::canceller_ptr ui::node::observe(method const &method, observing::caller<chain_pair_t>::handler_f &&handler) {
    return this->observe(std::vector<node::method>{method}, std::move(handler));
}

observing::canceller_ptr ui::node::observe(std::vector<method> const &methods,
                                           observing::caller<chain_pair_t>::handler_f &&handler) {
    for (auto const &method : methods) {
        if (this->_dispatch_cancellers.count(method) > 0) {
            continue;
        }

        observing::canceller_ptr canceller = nullptr;

        switch (method) {
            case ui::node::method::added_to_super:
            case ui::node::method::removed_from_super:
                canceller = this->_notifier->observe([this, method](node::method const &value) {
                    if (method == value) {
                        if (auto node = this->_weak_node.lock()) {
                            this->_dispatch_notifier->notify(std::make_pair(method, node));
                        }
                    }
                });
                break;
        }

        this->_dispatch_cancellers.emplace(method, std::move(canceller));
    }

    return this->_dispatch_notifier->observe([methods, handler = std::move(handler)](auto const &pair) {
        if (contains(methods, pair.first)) {
            handler(pair);
        }
    });
}

observing::canceller_ptr ui::node::observe_renderer(observing::caller<ui::renderer_ptr>::handler_f &&handler,
                                                    bool const sync) {
    return this->_renderer->observe(
        [handler = std::move(handler)](ui::renderer_wptr const &weak_renderer) {
            if (auto renderer = weak_renderer.lock()) {
                handler(renderer);
            } else {
                handler(nullptr);
            }
        },
        sync);
}

observing::canceller_ptr ui::node::observe_parent(observing::caller<ui::node_ptr>::handler_f &&handler,
                                                  bool const sync) {
    return this->_parent->observe(
        [handler = std::move(handler)](ui::node_wptr const &weak_node) {
            if (auto node = weak_node.lock()) {
                handler(node);
            } else {
                handler(nullptr);
            }
        },
        sync);
}

ui::point ui::node::convert_position(ui::point const &loc) const {
    auto const loc4 = simd::float4x4(matrix_invert(this->matrix())) * to_float4(loc.v);
    return {loc4.x, loc4.y};
}

void ui::node::attach_x_layout_guide(ui::layout_guide &guide) {
    this->_x_observer = guide.chain()
                            .perform([this](float const &x) {
                                this->_position->set_value(ui::point{x, this->position()->value().y});
                            })
                            .sync();

    this->_position_observer = nullptr;
}

void ui::node::attach_y_layout_guide(ui::layout_guide &guide) {
    this->_y_observer = guide.chain()
                            .perform([this](float const &y) {
                                this->_position->set_value(ui::point{this->position()->value().x, y});
                            })
                            .sync();

    this->_position_observer = nullptr;
}

void ui::node::attach_position_layout_guides(ui::layout_guide_point &guide_point) {
    this->_position_observer =
        guide_point.chain().perform([this](auto const &position) { this->_position->set_value(position); }).sync();

    this->_x_observer = nullptr;
    this->_y_observer = nullptr;
}

void ui::node::_prepare(ui::node_ptr const &node) {
    this->_weak_node = node;

    // enabled

    this->_enabled->observe([this](bool const &) { this->_set_updated(ui::node_update_reason::enabled); }, false)
        ->add_to(this->_pool);

    // geometry

    this->_position->observe([this](auto const &) { this->_set_updated(ui::node_update_reason::geometry); }, false)
        ->add_to(this->_pool);
    this->_angle->observe([this](auto const &) { this->_set_updated(ui::node_update_reason::geometry); }, false)
        ->add_to(this->_pool);
    this->_scale->observe([this](auto const &) { this->_set_updated(ui::node_update_reason::geometry); }, false)
        ->add_to(this->_pool);

    // mesh and mesh_color

    this->_mesh
        ->observe([this](auto const &) {
            this->_update_mesh_color();
            this->_set_updated(ui::node_update_reason::mesh);
        })
        ->add_to(this->_pool);

    this->_color->observe([this](ui::color const &color) { this->_update_mesh_color(); }, false)->add_to(this->_pool);
    this->_alpha->observe([this](float const &alpha) { this->_update_mesh_color(); }, false)->add_to(this->_pool);

    // collider

    this->_collider->observe([this](auto const &) { this->_set_updated(ui::node_update_reason::collider); }, false)
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

                this->_set_updated(ui::node_update_reason::batch);
            },
            false)
        ->add_to(this->_pool);

    // render_target

    this->_render_target
        ->observe([this](auto const &) { this->_set_updated(ui::node_update_reason::render_target); }, false)
        ->add_to(this->_pool);
}

ui::setup_metal_result ui::node::metal_setup(std::shared_ptr<ui::metal_system> const &metal_system) {
    if (auto const &mesh = this->_mesh->value()) {
        if (auto ul = unless(metal_object::cast(mesh)->metal_setup(metal_system))) {
            return std::move(ul.value);
        }
    }

    if (auto &render_target = this->_render_target->value()) {
        if (auto ul = unless(ui::metal_object::cast(render_target)->metal_setup(metal_system))) {
            return std::move(ul.value);
        }

        if (auto ul = unless(metal_object::cast(ui::renderable_render_target::cast(render_target)->mesh())
                                 ->metal_setup(metal_system))) {
            return std::move(ul.value);
        }

        if (auto &effect = ui::renderable_render_target::cast(render_target)->effect()) {
            if (auto ul = unless(metal_object::cast(effect)->metal_setup(metal_system))) {
                return std::move(ul.value);
            }
        }
    }

    if (auto &batch = this->_batch->value()) {
        if (auto ul = unless(ui::metal_object::cast(batch)->metal_setup(metal_system))) {
            return std::move(ul.value);
        }
    }

    for (auto &sub_node : this->_children) {
        if (auto ul = unless(ui::metal_object::cast(sub_node)->metal_setup(metal_system))) {
            return std::move(ul.value);
        }
    }

    return ui::setup_metal_result{nullptr};
}

void ui::node::set_renderer(ui::renderer_ptr const &renderer) {
    this->_renderer->set_value(renderer);
}

void ui::node::fetch_updates(ui::tree_updates &tree_updates) {
    if (this->_enabled->value()) {
        tree_updates.node_updates.flags |= this->_updates.flags;

        if (auto const &mesh = this->_mesh->value()) {
            tree_updates.mesh_updates.flags |= renderable_mesh::cast(mesh)->updates().flags;

            if (auto const &mesh_data = mesh->mesh_data()) {
                tree_updates.mesh_data_updates.flags |= ui::renderable_mesh_data::cast(mesh_data)->updates().flags;
            }
        }

        if (auto &render_target = this->_render_target->value()) {
            auto const renderable = ui::renderable_render_target::cast(render_target);

            tree_updates.render_target_updates.flags |= renderable->updates().flags;

            auto const &mesh = renderable->mesh();

            tree_updates.mesh_updates.flags |= renderable_mesh::cast(mesh)->updates().flags;

            if (auto &mesh_data = mesh->mesh_data()) {
                tree_updates.mesh_data_updates.flags |= ui::renderable_mesh_data::cast(mesh_data)->updates().flags;
            }

            if (auto &effect = renderable->effect()) {
                tree_updates.effect_updates.flags |= renderable_effect::cast(effect)->updates().flags;
            }
        }

        for (auto &sub_node : this->_children) {
            ui::renderable_node::cast(sub_node)->fetch_updates(tree_updates);
        }
    } else if (this->_updates.test(ui::node_update_reason::enabled)) {
        tree_updates.node_updates.set(ui::node_update_reason::enabled);
    }
}

void ui::node::build_render_info(ui::render_info &render_info) {
    if (this->_enabled->value()) {
        this->_update_local_matrix();

        this->_matrix = render_info.matrix * this->_local_matrix;
        auto const mesh_matrix = render_info.mesh_matrix * this->_local_matrix;

        if (auto const &collider = this->_collider->value()) {
            ui::renderable_collider::cast(collider)->set_matrix(this->_matrix);

            if (auto const &detector = render_info.detector) {
                auto const detector_updatable = updatable_detector::cast(detector);
                if (detector_updatable->is_updating()) {
                    detector_updatable->push_front_collider(collider);
                }
            }
        }

        if (auto const &render_encodable = render_info.render_encodable) {
            if (auto const &mesh = this->_mesh->value()) {
                renderable_mesh::cast(mesh)->set_matrix(mesh_matrix);
                render_encodable->append_mesh(mesh);
            }

            if (auto &render_target = this->_render_target->value()) {
                auto const &mesh = ui::renderable_render_target::cast(render_target)->mesh();
                renderable_mesh::cast(mesh)->set_matrix(mesh_matrix);
                render_encodable->append_mesh(mesh);
            }
        }

        if (auto const &render_target = this->_render_target->value()) {
            bool needs_render = this->_updates.test(ui::node_update_reason::render_target);

            if (!needs_render) {
                needs_render = ui::renderable_render_target::cast(render_target)->updates().flags.any();
            }

            auto const renderable = ui::renderable_render_target::cast(render_target);
            auto const &effect = renderable->effect();
            if (!needs_render && effect) {
                needs_render = renderable_effect::cast(effect)->updates().flags.any();
            }

            if (!needs_render) {
                ui::tree_updates tree_updates;

                for (auto &sub_node : this->_children) {
                    ui::renderable_node::cast(sub_node)->fetch_updates(tree_updates);
                }

                needs_render = tree_updates.is_any_updated();
            }

            if (needs_render) {
                auto const &stackable = render_info.render_stackable;

                if (ui::renderable_render_target::cast(render_target)->push_encode_info(stackable)) {
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
            ui::tree_updates tree_updates;

            for (auto const &sub_node : this->_children) {
                ui::renderable_node::cast(sub_node)->fetch_updates(tree_updates);
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

bool ui::node::is_rendering_color_exists() {
    if (!this->_enabled->value()) {
        return false;
    }

    for (auto &sub_node : this->_children) {
        if (ui::renderable_node::cast(sub_node)->is_rendering_color_exists()) {
            return true;
        }
    }

    if (auto const &mesh = this->_mesh->value()) {
        return renderable_mesh::cast(mesh)->is_rendering_color_exists();
    }

    return false;
}

void ui::node::clear_updates() {
    if (this->_enabled->value()) {
        this->_updates.flags.reset();

        if (auto const &mesh = this->_mesh->value()) {
            renderable_mesh::cast(mesh)->clear_updates();
        }

        if (auto &render_target = this->_render_target->value()) {
            ui::renderable_render_target::cast(render_target)->clear_updates();
        }

        for (auto &sub_node : this->_children) {
            ui::renderable_node::cast(sub_node)->clear_updates();
        }
    } else {
        this->_updates.reset(ui::node_update_reason::enabled);
    }
}

void ui::node::_add_sub_node(ui::node_ptr &sub_node, ui::node_ptr const &node) {
    ui::node_wptr weak_node = node;
    sub_node->_parent->set_value(std::move(weak_node));
    sub_node->_set_renderer_recursively(this->_renderer->value().lock());

    sub_node->_notifier->notify(method::added_to_super);

    this->_set_updated(ui::node_update_reason::children);
}

void ui::node::_remove_sub_node(ui::node_ptr const &sub_node) {
    ui::node_wptr weak_node = ui::node_ptr{nullptr};
    sub_node->_parent->set_value(std::move(weak_node));
    sub_node->_set_renderer_recursively(nullptr);

    erase_if(this->_children, [&sub_node](ui::node_ptr const &node) { return node == sub_node; });

    sub_node->_notifier->notify(method::removed_from_super);

    this->_set_updated(ui::node_update_reason::children);
}

void ui::node::_set_renderer_recursively(ui::renderer_ptr const &renderer) {
    this->_renderer->set_value(renderer);

    for (auto const &sub_node : this->_children) {
        sub_node->_set_renderer_recursively(renderer);
    }
}

void ui::node::_update_mesh_color() {
    if (auto const &mesh = this->_mesh->value()) {
        auto const &color = this->_color->value();
        auto const &alpha = this->_alpha->value();
        mesh->set_color({color.red, color.green, color.blue, alpha});
    }
}

void ui::node::_set_updated(ui::node_update_reason const reason) {
    this->_updates.set(reason);
}

void ui::node::_update_local_matrix() const {
    if (this->_updates.test(ui::node_update_reason::geometry)) {
        auto const &position = this->_position->value();
        auto const &angle = this->_angle->value();
        auto const &scale = this->_scale->value();
        this->_local_matrix = matrix::translation(position.x, position.y) * matrix::rotation(angle.degrees) *
                              matrix::scale(scale.width, scale.height);
    }
}

void ui::node::_update_matrix() const {
    if (auto locked_parent = this->_parent->value().lock()) {
        this->_matrix = locked_parent->matrix();
    } else {
        if (auto locked_renderer = this->renderer()) {
            this->_matrix = locked_renderer->projection_matrix();
        } else {
            this->_matrix = matrix_identity_float4x4;
        }
    }

    this->_update_local_matrix();

    this->_matrix = this->_matrix * this->_local_matrix;
}

std::shared_ptr<ui::node> ui::node::make_shared() {
    auto shared = std::shared_ptr<node>(new node{});
    shared->_prepare(shared);
    return shared;
}

std::string yas::to_string(ui::node::method const &method) {
    switch (method) {
        case ui::node::method::added_to_super:
            return "added_to_super";
        case ui::node::method::removed_from_super:
            return "removed_from_super";
    }
}

std::ostream &operator<<(std::ostream &os, yas::ui::node::method const &method) {
    os << to_string(method);
    return os;
}

bool yas::operator==(yas::ui::node_wptr const &lhs, yas::ui::node_wptr const &rhs) {
    auto locked_lhs = lhs.lock();
    auto locked_rhs = rhs.lock();
    return (locked_lhs && locked_rhs && locked_lhs == locked_rhs);
}

bool yas::operator!=(yas::ui::node_wptr const &lhs, yas::ui::node_wptr const &rhs) {
    auto locked_lhs = lhs.lock();
    auto locked_rhs = rhs.lock();
    return (!locked_lhs || !locked_rhs || locked_lhs != locked_rhs);
}

bool yas::ui::operator==(yas::ui::node_wptr const &lhs, yas::ui::node_wptr const &rhs) {
    auto locked_lhs = lhs.lock();
    auto locked_rhs = rhs.lock();
    return (locked_lhs && locked_rhs && locked_lhs == locked_rhs);
}

bool yas::ui::operator!=(yas::ui::node_wptr const &lhs, yas::ui::node_wptr const &rhs) {
    auto locked_lhs = lhs.lock();
    auto locked_rhs = rhs.lock();
    return (!locked_lhs || !locked_rhs || locked_lhs != locked_rhs);
}
