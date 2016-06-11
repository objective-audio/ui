//
//  yas_ui_node.mm
//

#include "yas_observing.h"
#include "yas_property.h"
#include "yas_ui_batch.h"
#include "yas_ui_batch_protocol.h"
#include "yas_ui_collider.h"
#include "yas_ui_collision_detector.h"
#include "yas_ui_matrix.h"
#include "yas_ui_mesh.h"
#include "yas_ui_mesh_data.h"
#include "yas_ui_metal_encode_info.h"
#include "yas_ui_node.h"
#include "yas_ui_render_info.h"
#include "yas_ui_renderer.h"
#include "yas_ui_types.h"
#include "yas_unless.h"

using namespace yas;

#pragma mark - node::impl

struct ui::node::impl : public base::impl, public renderable_node::impl, public metal_object::impl {
   public:
    impl() {
        _updates.flags.set();
    }

    std::vector<ui::node> &children() {
        return _children;
    }

    void push_front_sub_node(ui::node &&sub_node) {
        auto iterator = _children.emplace(_children.begin(), std::move(sub_node));
        _add_sub_node(*iterator);
    }

    void push_back_sub_node(ui::node &&sub_node) {
        _children.emplace_back(std::move(sub_node));
        _add_sub_node(_children.back());
    }

    void insert_sub_node(ui::node &&sub_node, std::size_t const idx) {
        auto iterator = _children.emplace(_children.begin() + idx, std::move(sub_node));
        _add_sub_node(*iterator);
    }

    void _add_sub_node(ui::node &sub_node) {
        auto sub_node_impl = sub_node.impl_ptr<impl>();

        sub_node_impl->_parent_property.set_value(cast<ui::node>());
        sub_node_impl->_set_renderer_recursively(_renderer_property.value().lock());

        if (sub_node_impl->_subject.has_observer()) {
            sub_node_impl->_subject.notify(node_method::added_to_super, sub_node);
        }

        if (auto renderer = _renderer_property.value().lock()) {
            _set_updated_for_collider(ui::collider_update_reason::existence);
        }
    }

    void remove_sub_node(ui::node const &sub_node) {
        auto sub_node_impl = sub_node.impl_ptr<impl>();

        sub_node_impl->_parent_property.set_value(ui::node{nullptr});
        sub_node_impl->_set_renderer_recursively(ui::renderer{nullptr});

        erase_if(_children, [&sub_node](ui::node const &node) { return node == sub_node; });

        if (sub_node_impl->_subject.has_observer()) {
            sub_node_impl->_subject.notify(node_method::removed_from_super, sub_node);
        }

        if (auto renderer = _renderer_property.value().lock()) {
            _set_updated_for_collider(ui::collider_update_reason::existence);
        }
    }

    void remove_from_super_node() {
        if (auto parent = _parent_property.value().lock()) {
            parent.impl_ptr<impl>()->remove_sub_node(cast<ui::node>());
        }
    }

    void fetch_render_info(ui::render_info &render_info) override {
        if (_enabled_property.value()) {
            if (_updates.test(ui::node_update_reason::geometry)) {
                auto const &position = _position_property.value();
                auto const &angle = _angle_property.value();
                auto const &scale = _scale_property.value();
                _local_matrix = matrix::translation(position.x, position.y) * matrix::rotation(angle) *
                                matrix::scale(scale.width, scale.height);
            }

            _matrix = render_info.matrix * _local_matrix;
            auto const mesh_matrix = render_info.mesh_matrix * _local_matrix;

            if (auto &collider = _collider_property.value()) {
                collider.renderable().set_matrix(_matrix);
                render_info.collision_detector.updatable().push_front_collider_if_needed(collider);
            }

            if (auto &render_encodable = render_info.render_encodable) {
                if (auto &mesh = _mesh_property.value()) {
                    mesh.renderable().set_matrix(mesh_matrix);
                    render_encodable.push_back_mesh(mesh);
                }
            }

            if (auto batch = _batch_property.value()) {
                ui::tree_updates tree_updates;

                for (auto &sub_node : _children) {
                    sub_node.renderable().fetch_tree_updates(tree_updates);
                }

                auto const building_type = tree_updates.batch_building_type();

                ui::render_info batch_render_info{.collision_detector = render_info.collision_detector};
                auto &batch_renderable = batch.renderable();

                if (building_type != ui::batch_building_type::none) {
                    batch_render_info.render_encodable = batch.encodable();
                    batch_renderable.begin_render_meshes_building(building_type);
                }

                for (auto &sub_node : _children) {
                    batch_render_info.matrix = _matrix;
                    batch_render_info.mesh_matrix = matrix_identity_float4x4;
                    sub_node.impl_ptr<impl>()->fetch_render_info(batch_render_info);
                }

                if (building_type != ui::batch_building_type::none) {
                    batch_renderable.commit_render_meshes_building();
                }

                for (auto &mesh : batch_renderable.meshes()) {
                    mesh.renderable().set_matrix(mesh_matrix);
                    render_info.render_encodable.push_back_mesh(mesh);
                }

                render_info.batches.push_back(batch);
            } else {
                for (auto &sub_node : _children) {
                    render_info.matrix = _matrix;
                    render_info.mesh_matrix = mesh_matrix;
                    sub_node.impl_ptr<impl>()->fetch_render_info(render_info);
                }
            }
        }
    }

    ui::setup_metal_result metal_setup(id<MTLDevice> const device) override {
        if (auto &mesh = _mesh_property.value()) {
            if (auto ul = unless(mesh.metal().metal_setup(device))) {
                return std::move(ul.value);
            }
        }

        for (auto &sub_node : _children) {
            if (auto ul = unless(sub_node.metal().metal_setup(device))) {
                return std::move(ul.value);
            }
        }

        return ui::setup_metal_result{nullptr};
    }

    ui::renderer renderer() override {
        return _renderer_property.value().lock();
    }

    void set_renderer(ui::renderer &&renderer) override {
        _renderer_property.set_value(renderer);
    }

    void fetch_tree_updates(ui::tree_updates &tree_updates) override {
        tree_updates.node_updates.flags |= _updates.flags;

        if (_enabled_property.value()) {
            if (auto &mesh = _mesh_property.value()) {
                tree_updates.mesh_updates.flags |= mesh.renderable().updates().flags;

                if (auto &mesh_data = mesh.mesh_data()) {
                    tree_updates.mesh_data_updates.flags |= mesh_data.renderable().updates().flags;
                }
            }

            for (auto &sub_node : _children) {
                sub_node.renderable().fetch_tree_updates(tree_updates);
            }
        }
    }

    bool is_rendering_color_exists() override {
        if (!_enabled_property.value()) {
            return false;
        }

        for (auto &sub_node : _children) {
            if (sub_node.renderable().is_rendering_color_exists()) {
                return true;
            }
        }

        if (auto &mesh = _mesh_property.value()) {
            return mesh.renderable().is_rendering_color_exists();
        }

        return false;
    }

    void clear_updates() override {
        _updates.flags.reset();

        if (auto &mesh = _mesh_property.value()) {
            mesh.renderable().clear_updates();
        }

        for (auto &sub_node : _children) {
            sub_node.renderable().clear_updates();
        }
    }

    ui::point convert_position(ui::point const &loc) {
        auto const loc4 = simd::float4x4(matrix_invert(_matrix)) * simd::float4{loc.x, loc.y, 0.0f, 0.0f};
        return {loc4.x, loc4.y};
    }

    void _set_renderer_recursively(ui::renderer const &renderer) {
        _renderer_property.set_value(renderer);

        for (auto &sub_node : _children) {
            sub_node.impl_ptr<impl>()->_set_renderer_recursively(renderer);
        }
    }

    void _update_mesh_color() {
        if (auto &mesh = _mesh_property.value()) {
            auto const &color = _color_property.value();
            auto const &alpha = _alpha_property.value();
            mesh.set_color({color.red, color.green, color.blue, alpha});
        }
    }

    void _set_updated_for_collider(ui::collider_update_reason const reason) {
        if (auto locked_renderer = renderer()) {
            locked_renderer.collision_detector().updatable().set_updated(reason);
        }
    }

    void _set_updated(ui::node_update_reason const reason) {
        _updates.set(reason);
    }

    property<weak<ui::node>> _parent_property{{.value = ui::node{nullptr}}};
    property<weak<ui::renderer>> _renderer_property{{.value = ui::renderer{nullptr}}};

    property<ui::point> _position_property{{.value = 0.0f}};
    property<float> _angle_property{{.value = 0.0f}};
    property<ui::size> _scale_property{{.value = 1.0f}};
    property<ui::color> _color_property{{.value = 1.0f}};
    property<float> _alpha_property{{.value = 1.0f}};
    property<ui::mesh> _mesh_property{{.value = nullptr}};
    property<ui::collider> _collider_property{{.value = nullptr}};
    property<ui::batch> _batch_property{{.value = nullptr}};
    property<bool> _enabled_property{{.value = true}};

    node::subject_t _subject;
    std::vector<base> _property_observers;

   private:
    std::vector<ui::node> _children;

    simd::float4x4 _matrix = matrix_identity_float4x4;
    simd::float4x4 _local_matrix = matrix_identity_float4x4;

    node_updates_t _updates;
};

#pragma mark - node

ui::node::node() : base(std::make_shared<impl>()) {
    auto imp_ptr = impl_ptr<impl>();
    auto &observers = imp_ptr->_property_observers;
    auto weak_node = to_weak(*this);

    observers.reserve(9);

    observers.emplace_back(imp_ptr->_enabled_property.subject().make_observer(
        property_method::did_change, [weak_node](auto const &context) {
            if (auto node = weak_node.lock()) {
                auto imp_ptr = node.impl_ptr<impl>();
                imp_ptr->_set_updated_for_collider(ui::collider_update_reason::existence);
                if (!context.value.new_value || node.renderable().is_rendering_color_exists()) {
                    imp_ptr->_set_updated(ui::node_update_reason::enabled);
                }
            }
        }));

    observers.emplace_back(
        imp_ptr->_position_property.subject().make_observer(property_method::did_change, [weak_node](auto const &) {
            if (auto node = weak_node.lock()) {
                if (node.renderable().is_rendering_color_exists()) {
                    node.impl_ptr<impl>()->_set_updated(ui::node_update_reason::geometry);
                }
            }
        }));

    observers.emplace_back(
        imp_ptr->_angle_property.subject().make_observer(property_method::did_change, [weak_node](auto const &) {
            if (auto node = weak_node.lock()) {
                if (node.renderable().is_rendering_color_exists()) {
                    node.impl_ptr<impl>()->_set_updated(ui::node_update_reason::geometry);
                }
            }
        }));

    observers.emplace_back(
        imp_ptr->_scale_property.subject().make_observer(property_method::did_change, [weak_node](auto const &) {
            if (auto node = weak_node.lock()) {
                if (node.renderable().is_rendering_color_exists()) {
                    node.impl_ptr<impl>()->_set_updated(ui::node_update_reason::geometry);
                }
            }
        }));

    observers.emplace_back(
        imp_ptr->_mesh_property.subject().make_observer(property_method::did_change, [weak_node](auto const &) {
            if (auto node = weak_node.lock()) {
                node.impl_ptr<impl>()->_update_mesh_color();
            }
        }));

    observers.emplace_back(
        imp_ptr->_color_property.subject().make_observer(property_method::did_change, [weak_node](auto const &) {
            if (auto node = weak_node.lock()) {
                node.impl_ptr<impl>()->_update_mesh_color();
            }
        }));

    observers.emplace_back(
        imp_ptr->_alpha_property.subject().make_observer(property_method::did_change, [weak_node](auto const &) {
            if (auto node = weak_node.lock()) {
                node.impl_ptr<impl>()->_update_mesh_color();
            }
        }));

    observers.emplace_back(
        imp_ptr->_collider_property.subject().make_observer(property_method::did_change, [weak_node](auto const &) {
            if (auto node = weak_node.lock()) {
                node.impl_ptr<impl>()->_set_updated_for_collider(ui::collider_update_reason::existence);
            }
        }));

    observers.emplace_back(
        imp_ptr->_batch_property.subject().make_observer(property_method::did_change, [weak_node](auto const &) {
            if (auto node = weak_node.lock()) {
                node.impl_ptr<impl>()->_set_updated(ui::node_update_reason::batch);
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
    return impl_ptr<impl>()->_position_property.value();
}

float ui::node::angle() const {
    return impl_ptr<impl>()->_angle_property.value();
}

ui::size ui::node::scale() const {
    return impl_ptr<impl>()->_scale_property.value();
}

ui::color ui::node::color() const {
    return impl_ptr<impl>()->_color_property.value();
}

float ui::node::alpha() const {
    return impl_ptr<impl>()->_alpha_property.value();
}

bool ui::node::is_enabled() const {
    return impl_ptr<impl>()->_enabled_property.value();
}

ui::mesh const &ui::node::mesh() const {
    return impl_ptr<impl>()->_mesh_property.value();
}

ui::mesh &ui::node::mesh() {
    return impl_ptr<impl>()->_mesh_property.value();
}

ui::collider const &ui::node::collider() const {
    return impl_ptr<impl>()->_collider_property.value();
}

ui::collider &ui::node::collider() {
    return impl_ptr<impl>()->_collider_property.value();
}

ui::batch const &ui::node::batch() const {
    return impl_ptr<impl>()->_batch_property.value();
}

ui::batch &ui::node::batch() {
    return impl_ptr<impl>()->_batch_property.value();
}

void ui::node::set_position(ui::point point) {
    impl_ptr<impl>()->_position_property.set_value(std::move(point));
}

void ui::node::set_angle(float const angle) {
    impl_ptr<impl>()->_angle_property.set_value(angle);
}

void ui::node::set_scale(ui::size scale) {
    impl_ptr<impl>()->_scale_property.set_value(std::move(scale));
}

void ui::node::set_color(ui::color color) {
    impl_ptr<impl>()->_color_property.set_value(std::move(color));
}

void ui::node::set_alpha(float const alpha) {
    impl_ptr<impl>()->_alpha_property.set_value(alpha);
}

void ui::node::set_mesh(ui::mesh mesh) {
    impl_ptr<impl>()->_mesh_property.set_value(std::move(mesh));
}

void ui::node::set_collider(ui::collider collider) {
    impl_ptr<impl>()->_collider_property.set_value(std::move(collider));
}

void ui::node::set_batch(ui::batch batch) {
    if (batch) {
        batch.renderable().clear_render_meshes();
    }
    impl_ptr<impl>()->_batch_property.set_value(std::move(batch));
}

void ui::node::set_enabled(bool const enabled) {
    impl_ptr<impl>()->_enabled_property.set_value(enabled);
}

void ui::node::push_front_sub_node(ui::node sub_node) {
    impl_ptr<impl>()->push_front_sub_node(std::move(sub_node));
}

void ui::node::push_back_sub_node(ui::node sub_node) {
    impl_ptr<impl>()->push_back_sub_node(std::move(sub_node));
}

void ui::node::insert_sub_node(ui::node sub_node, std::size_t const idx) {
    impl_ptr<impl>()->insert_sub_node(std::move(sub_node), idx);
}

void ui::node::remove_from_super_node() {
    impl_ptr<impl>()->remove_from_super_node();
}

std::vector<ui::node> const &ui::node::children() const {
    return impl_ptr<impl>()->children();
}

std::vector<ui::node> &ui::node::children() {
    return impl_ptr<impl>()->children();
}

ui::node ui::node::parent() const {
    return impl_ptr<impl>()->_parent_property.value().lock();
}

ui::renderer ui::node::renderer() const {
    return impl_ptr<impl>()->renderer();
}

ui::metal_object &ui::node::metal() {
    if (!_metal_object) {
        _metal_object = ui::metal_object{impl_ptr<ui::metal_object::impl>()};
    }
    return _metal_object;
}

ui::renderable_node &ui::node::renderable() {
    if (!_renderable) {
        _renderable = ui::renderable_node{impl_ptr<ui::renderable_node::impl>()};
    }
    return _renderable;
}

ui::node::subject_t &ui::node::subject() {
    return impl_ptr<impl>()->_subject;
}

void ui::node::dispatch_method(ui::node_method const method) {
    auto imp_ptr = impl_ptr<impl>();
    auto weak_node = to_weak(*this);

    base observer = nullptr;

    switch (method) {
        case ui::node_method::position_changed:
            observer = imp_ptr->_position_property.subject().make_observer(
                property_method::did_change, [weak_node](auto const &context) {
                    if (auto node = weak_node.lock()) {
                        node.subject().notify(node_method::position_changed, node);
                    }
                });
            break;
        case ui::node_method::angle_changed:
            observer = imp_ptr->_angle_property.subject().make_observer(
                property_method::did_change, [weak_node](auto const &context) {
                    if (auto node = weak_node.lock()) {
                        node.subject().notify(node_method::angle_changed, node);
                    }
                });
            break;
        case ui::node_method::scale_changed:
            observer = imp_ptr->_scale_property.subject().make_observer(
                property_method::did_change, [weak_node](auto const &context) {
                    if (auto node = weak_node.lock()) {
                        node.subject().notify(node_method::scale_changed, node);
                    }
                });
            break;
        case ui::node_method::color_changed:
            observer = imp_ptr->_color_property.subject().make_observer(
                property_method::did_change, [weak_node](auto const &context) {
                    if (auto node = weak_node.lock()) {
                        node.subject().notify(node_method::color_changed, node);
                    }
                });
            break;
        case ui::node_method::alpha_changed:
            observer = imp_ptr->_alpha_property.subject().make_observer(
                property_method::did_change, [weak_node](auto const &context) {
                    if (auto node = weak_node.lock()) {
                        node.subject().notify(node_method::alpha_changed, node);
                    }
                });
            break;
        case ui::node_method::enabled_changed:
            observer = imp_ptr->_enabled_property.subject().make_observer(
                property_method::did_change, [weak_node](auto const &context) {
                    if (auto node = weak_node.lock()) {
                        node.subject().notify(node_method::enabled_changed, node);
                    }
                });
            break;
        case ui::node_method::mesh_changed:
            observer = imp_ptr->_mesh_property.subject().make_observer(
                property_method::did_change, [weak_node](auto const &context) {
                    if (auto node = weak_node.lock()) {
                        node.subject().notify(node_method::mesh_changed, node);
                    }
                });
            break;
        case ui::node_method::collider_changed:
            observer = imp_ptr->_collider_property.subject().make_observer(
                property_method::did_change, [weak_node](auto const &context) {
                    if (auto node = weak_node.lock()) {
                        node.subject().notify(node_method::collider_changed, node);
                    }
                });
            break;
        case ui::node_method::parent_changed:
            observer = imp_ptr->_parent_property.subject().make_observer(
                property_method::did_change, [weak_node](auto const &context) {
                    if (auto node = weak_node.lock()) {
                        node.subject().notify(node_method::parent_changed, node);
                    }
                });
            break;
        case ui::node_method::renderer_changed:
            observer = imp_ptr->_renderer_property.subject().make_observer(
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
