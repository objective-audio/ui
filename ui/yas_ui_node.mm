//
//  yas_ui_node.mm
//

#include "yas_ui_collision_detector.h"
#include "yas_ui_node.h"
#include "yas_ui_renderer.h"

using namespace yas;

#pragma mark - node

ui::node::node() : base(std::make_shared<impl>()) {
    auto imp_ptr = impl_ptr<impl>();
    auto &observers = imp_ptr->_property_observers;
    auto weak_node = to_weak(*this);

    observers.reserve(8);

    observers.emplace_back(
        imp_ptr->position_property.subject().make_observer(property_method::did_change, [weak_node](auto const &) {
            if (auto node = weak_node.lock()) {
                node.impl_ptr<impl>()->_set_needs_update_matrix();
            }
        }));

    observers.emplace_back(
        imp_ptr->angle_property.subject().make_observer(property_method::did_change, [weak_node](auto const &) {
            if (auto node = weak_node.lock()) {
                node.impl_ptr<impl>()->_set_needs_update_matrix();
            }
        }));

    observers.emplace_back(
        imp_ptr->scale_property.subject().make_observer(property_method::did_change, [weak_node](auto const &) {
            if (auto node = weak_node.lock()) {
                node.impl_ptr<impl>()->_set_needs_update_matrix();
            }
        }));

    observers.emplace_back(
        imp_ptr->mesh_property.subject().make_observer(property_method::did_change, [weak_node](auto const &) {
            if (auto node = weak_node.lock()) {
                node.impl_ptr<impl>()->_update_mesh_color();
            }
        }));

    observers.emplace_back(
        imp_ptr->color_property.subject().make_observer(property_method::did_change, [weak_node](auto const &) {
            if (auto node = weak_node.lock()) {
                node.impl_ptr<impl>()->_update_mesh_color();
            }
        }));

    observers.emplace_back(
        imp_ptr->alpha_property.subject().make_observer(property_method::did_change, [weak_node](auto const &) {
            if (auto node = weak_node.lock()) {
                node.impl_ptr<impl>()->_update_mesh_color();
            }
        }));

    observers.emplace_back(
        imp_ptr->collider_property.subject().make_observer(property_method::did_change, [weak_node](auto const &) {
            if (auto node = weak_node.lock()) {
                if (auto renderer = node.renderer()) {
                    renderer.collision_detector().updatable().set_needs_update_colliders();
                }
            }
        }));
}

ui::node::node(std::nullptr_t) : base(nullptr) {
}

bool ui::node::operator==(ui::node const &rhs) const {
    return base::operator==(rhs);
}

bool ui::node::operator!=(ui::node const &rhs) const {
    return base::operator!=(rhs);
}

ui::point ui::node::position() const {
    return impl_ptr<impl>()->position_property.value();
}

float ui::node::angle() const {
    return impl_ptr<impl>()->angle_property.value();
}

ui::size ui::node::scale() const {
    return impl_ptr<impl>()->scale_property.value();
}

ui::color ui::node::color() const {
    return impl_ptr<impl>()->color_property.value();
}

float ui::node::alpha() const {
    return impl_ptr<impl>()->alpha_property.value();
}

bool ui::node::is_enabled() const {
    return impl_ptr<impl>()->enabled_property.value();
}

ui::mesh const &ui::node::mesh() const {
    return impl_ptr<impl>()->mesh_property.value();
}

ui::mesh &ui::node::mesh() {
    return impl_ptr<impl>()->mesh_property.value();
}

ui::collider const &ui::node::collider() const {
    return impl_ptr<impl>()->collider_property.value();
}

ui::collider &ui::node::collider() {
    return impl_ptr<impl>()->collider_property.value();
}

void ui::node::set_position(ui::point point) {
    impl_ptr<impl>()->position_property.set_value(std::move(point));
}

void ui::node::set_angle(float const angle) {
    impl_ptr<impl>()->angle_property.set_value(angle);
}

void ui::node::set_scale(ui::size scale) {
    impl_ptr<impl>()->scale_property.set_value(std::move(scale));
}

void ui::node::set_color(ui::color color) {
    impl_ptr<impl>()->color_property.set_value(std::move(color));
}

void ui::node::set_alpha(float const alpha) {
    impl_ptr<impl>()->alpha_property.set_value(alpha);
}

void ui::node::set_mesh(ui::mesh mesh) {
    impl_ptr<impl>()->mesh_property.set_value(std::move(mesh));
}

void ui::node::set_collider(ui::collider collider) {
    impl_ptr<impl>()->collider_property.set_value(std::move(collider));
}

void ui::node::set_enabled(bool const enabled) {
    impl_ptr<impl>()->enabled_property.set_value(enabled);
}

void ui::node::add_sub_node(ui::node sub_node) {
    impl_ptr<impl>()->add_sub_node(std::move(sub_node));
}

void ui::node::remove_from_super_node() {
    impl_ptr<impl>()->remove_from_super_node();
}

std::vector<ui::node> const &ui::node::children() const {
    return impl_ptr<impl>()->children();
}

ui::node ui::node::parent() const {
    return impl_ptr<impl>()->parent_property.value().lock();
}

ui::node_renderer ui::node::renderer() const {
    return impl_ptr<impl>()->renderer();
}

void ui::node::update_render_info(render_info &info) {
    impl_ptr<impl>()->update_render_info(info);
}

ui::metal_object ui::node::metal() {
    return ui::metal_object{impl_ptr<ui::metal_object::impl>()};
}

ui::renderable_node ui::node::renderable() {
    return ui::renderable_node{impl_ptr<ui::renderable_node::impl>()};
}

ui::node::subject_t &ui::node::subject() {
    return impl_ptr<impl>()->subject;
}

void ui::node::dispatch_method(ui::node_method const method) {
    auto imp_ptr = impl_ptr<impl>();
    auto weak_node = to_weak(*this);

    base observer = nullptr;

    switch (method) {
        case ui::node_method::position_changed:
            observer = imp_ptr->position_property.subject().make_observer(
                property_method::did_change, [weak_node](auto const &context) {
                    if (auto node = weak_node.lock()) {
                        node.subject().notify(node_method::position_changed, node);
                    }
                });
            break;
        case ui::node_method::angle_changed:
            observer = imp_ptr->angle_property.subject().make_observer(
                property_method::did_change, [weak_node](auto const &context) {
                    if (auto node = weak_node.lock()) {
                        node.subject().notify(node_method::angle_changed, node);
                    }
                });
            break;
        case ui::node_method::scale_changed:
            observer = imp_ptr->scale_property.subject().make_observer(
                property_method::did_change, [weak_node](auto const &context) {
                    if (auto node = weak_node.lock()) {
                        node.subject().notify(node_method::scale_changed, node);
                    }
                });
            break;
        case ui::node_method::color_changed:
            observer = imp_ptr->color_property.subject().make_observer(
                property_method::did_change, [weak_node](auto const &context) {
                    if (auto node = weak_node.lock()) {
                        node.subject().notify(node_method::color_changed, node);
                    }
                });
            break;
        case ui::node_method::alpha_changed:
            observer = imp_ptr->alpha_property.subject().make_observer(
                property_method::did_change, [weak_node](auto const &context) {
                    if (auto node = weak_node.lock()) {
                        node.subject().notify(node_method::alpha_changed, node);
                    }
                });
            break;
        case ui::node_method::enabled_changed:
            observer = imp_ptr->enabled_property.subject().make_observer(
                property_method::did_change, [weak_node](auto const &context) {
                    if (auto node = weak_node.lock()) {
                        node.subject().notify(node_method::enabled_changed, node);
                    }
                });
            break;
        case ui::node_method::mesh_changed:
            observer = imp_ptr->mesh_property.subject().make_observer(
                property_method::did_change, [weak_node](auto const &context) {
                    if (auto node = weak_node.lock()) {
                        node.subject().notify(node_method::mesh_changed, node);
                    }
                });
            break;
        case ui::node_method::collider_changed:
            observer = imp_ptr->collider_property.subject().make_observer(
                property_method::did_change, [weak_node](auto const &context) {
                    if (auto node = weak_node.lock()) {
                        node.subject().notify(node_method::collider_changed, node);
                    }
                });
            break;
        case ui::node_method::parent_changed:
            observer = imp_ptr->parent_property.subject().make_observer(
                property_method::did_change, [weak_node](auto const &context) {
                    if (auto node = weak_node.lock()) {
                        node.subject().notify(node_method::parent_changed, node);
                    }
                });
            break;
        case ui::node_method::renderer_changed:
            observer = imp_ptr->node_renderer_property.subject().make_observer(
                property_method::did_change, [weak_node](auto const &context) {
                    if (auto node = weak_node.lock()) {
                        node.subject().notify(node_method::renderer_changed, node);
                    }
                });
            break;

        default:
            break;
    }

    if (observer) {
        imp_ptr->_property_observers.emplace_back(std::move(observer));
    }
}

ui::point ui::node::convert_position(ui::point const &loc) const {
    return impl_ptr<impl>()->convert_position(loc);
}
