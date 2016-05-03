//
//  yas_ui_node.mm
//

#include "yas_ui_node.h"
#include "yas_ui_renderer.h"

using namespace yas;

#pragma mark - node

ui::node::node() : base(std::make_shared<impl>()) {
    auto imp_ptr = impl_ptr<impl>();
    auto &observers = imp_ptr->_property_observers;
    auto weak_node = to_weak(*this);

    observers.reserve(8);

    observers.emplace_back(position().subject().make_observer(property_method::did_change, [weak_node](auto const &) {
        if (auto node = weak_node.lock()) {
            node.impl_ptr<impl>()->_set_needs_update_matrix();
        }
    }));

    observers.emplace_back(angle().subject().make_observer(property_method::did_change, [weak_node](auto const &) {
        if (auto node = weak_node.lock()) {
            node.impl_ptr<impl>()->_set_needs_update_matrix();
        }
    }));

    observers.emplace_back(scale().subject().make_observer(property_method::did_change, [weak_node](auto const &) {
        if (auto node = weak_node.lock()) {
            node.impl_ptr<impl>()->_set_needs_update_matrix();
        }
    }));

    observers.emplace_back(mesh().subject().make_observer(property_method::did_change, [weak_node](auto const &) {
        if (auto node = weak_node.lock()) {
            node.impl_ptr<impl>()->_udpate_mesh_color();
        }
    }));

    observers.emplace_back(color().subject().make_observer(property_method::did_change, [weak_node](auto const &) {
        if (auto node = weak_node.lock()) {
            node.impl_ptr<impl>()->_udpate_mesh_color();
        }
    }));

    observers.emplace_back(alpha().subject().make_observer(property_method::did_change, [weak_node](auto const &) {
        if (auto node = weak_node.lock()) {
            node.impl_ptr<impl>()->_udpate_mesh_color();
        }
    }));

    observers.emplace_back(
        imp_ptr->parent_property.subject().make_observer(property_method::did_change, [weak_node](auto const &context) {
            if (auto node = weak_node.lock()) {
                node.subject().notify(node_method::change_parent, node);
            }
        }));

    observers.emplace_back(imp_ptr->node_renderer_property.subject().make_observer(
        property_method::did_change, [weak_node](auto const &context) {
            if (auto node = weak_node.lock()) {
                node.subject().notify(node_method::change_node_renderer, node);
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

property<ui::point> const &ui::node::position() const {
    return impl_ptr<impl>()->position_property;
}

property<float> const &ui::node::angle() const {
    return impl_ptr<impl>()->angle_property;
}

property<ui::size> const &ui::node::scale() const {
    return impl_ptr<impl>()->scale_property;
}

property<ui::color> const &ui::node::color() const {
    return impl_ptr<impl>()->color_property;
}

property<float> const &ui::node::alpha() const {
    return impl_ptr<impl>()->alpha_property;
}

property<ui::mesh> const &ui::node::mesh() const {
    return impl_ptr<impl>()->mesh_property;
}

property<ui::collider> const &ui::node::collider() const {
    return impl_ptr<impl>()->collider_property;
}

property<bool> const &ui::node::enabled() const {
    return impl_ptr<impl>()->enabled_property;
}

property<ui::point> &ui::node::position() {
    return impl_ptr<impl>()->position_property;
}

property<float> &ui::node::angle() {
    return impl_ptr<impl>()->angle_property;
}

property<ui::size> &ui::node::scale() {
    return impl_ptr<impl>()->scale_property;
}

property<ui::color> &ui::node::color() {
    return impl_ptr<impl>()->color_property;
}

property<float> &ui::node::alpha() {
    return impl_ptr<impl>()->alpha_property;
}

property<ui::mesh> &ui::node::mesh() {
    return impl_ptr<impl>()->mesh_property;
}

property<ui::collider> &ui::node::collider() {
    return impl_ptr<impl>()->collider_property;
}

property<bool> &ui::node::enabled() {
    return impl_ptr<impl>()->enabled_property;
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

ui::point ui::node::convert_position(ui::point const &loc) const {
    return impl_ptr<impl>()->convert_position(loc);
}
