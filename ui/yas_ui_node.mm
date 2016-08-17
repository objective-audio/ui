//
//  yas_ui_node.mm
//

#include "yas_observing.h"
#include "yas_property.h"
#include "yas_to_bool.h"
#include "yas_ui_batch.h"
#include "yas_ui_batch_protocol.h"
#include "yas_ui_collider.h"
#include "yas_ui_detector.h"
#include "yas_ui_layout_guide.h"
#include "yas_ui_matrix.h"
#include "yas_ui_mesh.h"
#include "yas_ui_mesh_data.h"
#include "yas_ui_metal_encode_info.h"
#include "yas_ui_metal_system.h"
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

    void setup_observers() {
        auto weak_node = to_weak(cast<ui::node>());

        _property_observers.reserve(9);

        _property_observers.emplace_back(
            _enabled_property.subject().make_observer(property_method::did_change, [weak_node](auto const &context) {
                if (auto node = weak_node.lock()) {
                    node.impl_ptr<impl>()->_set_updated(ui::node_update_reason::enabled);
                }
            }));

        _property_observers.emplace_back(
            _position_property.subject().make_observer(property_method::did_change, [weak_node](auto const &) {
                if (auto node = weak_node.lock()) {
                    node.impl_ptr<impl>()->_set_updated(ui::node_update_reason::geometry);
                }
            }));

        _property_observers.emplace_back(
            _angle_property.subject().make_observer(property_method::did_change, [weak_node](auto const &) {
                if (auto node = weak_node.lock()) {
                    node.impl_ptr<impl>()->_set_updated(ui::node_update_reason::geometry);
                }
            }));

        _property_observers.emplace_back(
            _scale_property.subject().make_observer(property_method::did_change, [weak_node](auto const &) {
                if (auto node = weak_node.lock()) {
                    node.impl_ptr<impl>()->_set_updated(ui::node_update_reason::geometry);
                }
            }));

        _property_observers.emplace_back(
            _mesh_property.subject().make_observer(property_method::did_change, [weak_node](auto const &) {
                if (auto node = weak_node.lock()) {
                    node.impl_ptr<impl>()->_update_mesh_color();
                }
            }));

        _property_observers.emplace_back(
            _color_property.subject().make_observer(property_method::did_change, [weak_node](auto const &) {
                if (auto node = weak_node.lock()) {
                    node.impl_ptr<impl>()->_update_mesh_color();
                }
            }));

        _property_observers.emplace_back(
            _alpha_property.subject().make_observer(property_method::did_change, [weak_node](auto const &) {
                if (auto node = weak_node.lock()) {
                    node.impl_ptr<impl>()->_update_mesh_color();
                }
            }));

        _property_observers.emplace_back(
            _collider_property.subject().make_observer(property_method::did_change, [weak_node](auto const &) {
                if (auto node = weak_node.lock()) {
                    node.impl_ptr<impl>()->_set_updated(ui::node_update_reason::collider);
                }
            }));

        _property_observers.emplace_back(
            _batch_property.subject().make_observer(property_method::did_change, [weak_node](auto const &) {
                if (auto node = weak_node.lock()) {
                    node.impl_ptr<impl>()->_set_updated(ui::node_update_reason::batch);
                }
            }));
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

    void remove_from_super_node() {
        if (auto parent = _parent_property.value().lock()) {
            parent.impl_ptr<impl>()->_remove_sub_node(cast<ui::node>());
        }
    }

    void set_batch(ui::batch &&batch) {
        if (batch) {
            batch.renderable().clear_render_meshes();
        }

        if (auto &old_batch = _batch_property.value()) {
            old_batch.renderable().clear_render_meshes();
        }

        _batch_property.set_value(std::move(batch));
    }

    void build_render_info(ui::render_info &render_info) override {
        if (_enabled_property.value()) {
            _update_local_matrix();

            _matrix = render_info.matrix * _local_matrix;
            auto const mesh_matrix = render_info.mesh_matrix * _local_matrix;

            if (auto &collider = _collider_property.value()) {
                collider.renderable().set_matrix(_matrix);

                if (auto &detector = render_info.detector) {
                    auto &detector_updatable = detector.updatable();
                    if (detector_updatable.is_updating()) {
                        detector_updatable.push_front_collider(collider);
                    }
                }
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
                    sub_node.renderable().fetch_updates(tree_updates);
                }

                auto const building_type = tree_updates.batch_building_type();

                ui::render_info batch_render_info{.detector = render_info.detector};
                auto &batch_renderable = batch.renderable();

                if (to_bool(building_type)) {
                    batch_render_info.render_encodable = batch.encodable();
                    batch_renderable.begin_render_meshes_building(building_type);
                }

                for (auto &sub_node : _children) {
                    batch_render_info.matrix = _matrix;
                    batch_render_info.mesh_matrix = matrix_identity_float4x4;
                    sub_node.impl_ptr<impl>()->build_render_info(batch_render_info);
                }

                if (to_bool(building_type)) {
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
                    sub_node.impl_ptr<impl>()->build_render_info(render_info);
                }
            }
        }
    }

    ui::setup_metal_result metal_setup(ui::metal_system const &metal_system) override {
        if (auto &mesh = _mesh_property.value()) {
            if (auto ul = unless(mesh.metal().metal_setup(metal_system))) {
                return std::move(ul.value);
            }
        }

        for (auto &sub_node : _children) {
            if (auto ul = unless(sub_node.metal().metal_setup(metal_system))) {
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

    void fetch_updates(ui::tree_updates &tree_updates) override {
        tree_updates.node_updates.flags |= _updates.flags;

        if (_enabled_property.value()) {
            if (auto &mesh = _mesh_property.value()) {
                tree_updates.mesh_updates.flags |= mesh.renderable().updates().flags;

                if (auto &mesh_data = mesh.mesh_data()) {
                    tree_updates.mesh_data_updates.flags |= mesh_data.renderable().updates().flags;
                }
            }

            for (auto &sub_node : _children) {
                sub_node.renderable().fetch_updates(tree_updates);
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

    void dispatch_method(ui::node::method const method) {
        auto weak_node = to_weak(cast<ui::node>());

        base observer = nullptr;

        switch (method) {
            case ui::node::method::position_changed:
                observer = _position_property.subject().make_observer(
                    property_method::did_change, [weak_node](auto const &context) {
                        if (auto node = weak_node.lock()) {
                            node.subject().notify(node::method::position_changed, node);
                        }
                    });
                break;
            case ui::node::method::angle_changed:
                observer = _angle_property.subject().make_observer(
                    property_method::did_change, [weak_node](auto const &context) {
                        if (auto node = weak_node.lock()) {
                            node.subject().notify(node::method::angle_changed, node);
                        }
                    });
                break;
            case ui::node::method::scale_changed:
                observer = _scale_property.subject().make_observer(
                    property_method::did_change, [weak_node](auto const &context) {
                        if (auto node = weak_node.lock()) {
                            node.subject().notify(node::method::scale_changed, node);
                        }
                    });
                break;
            case ui::node::method::color_changed:
                observer = _color_property.subject().make_observer(
                    property_method::did_change, [weak_node](auto const &context) {
                        if (auto node = weak_node.lock()) {
                            node.subject().notify(node::method::color_changed, node);
                        }
                    });
                break;
            case ui::node::method::alpha_changed:
                observer = _alpha_property.subject().make_observer(
                    property_method::did_change, [weak_node](auto const &context) {
                        if (auto node = weak_node.lock()) {
                            node.subject().notify(node::method::alpha_changed, node);
                        }
                    });
                break;
            case ui::node::method::enabled_changed:
                observer = _enabled_property.subject().make_observer(
                    property_method::did_change, [weak_node](auto const &context) {
                        if (auto node = weak_node.lock()) {
                            node.subject().notify(node::method::enabled_changed, node);
                        }
                    });
                break;
            case ui::node::method::mesh_changed:
                observer = _mesh_property.subject().make_observer(
                    property_method::did_change, [weak_node](auto const &context) {
                        if (auto node = weak_node.lock()) {
                            node.subject().notify(node::method::mesh_changed, node);
                        }
                    });
                break;
            case ui::node::method::collider_changed:
                observer = _collider_property.subject().make_observer(
                    property_method::did_change, [weak_node](auto const &context) {
                        if (auto node = weak_node.lock()) {
                            node.subject().notify(node::method::collider_changed, node);
                        }
                    });
                break;
            case ui::node::method::parent_changed:
                observer = _parent_property.subject().make_observer(
                    property_method::did_change, [weak_node](auto const &context) {
                        if (auto node = weak_node.lock()) {
                            node.subject().notify(node::method::parent_changed, node);
                        }
                    });
                break;
            case ui::node::method::renderer_changed:
                observer = _renderer_property.subject().make_observer(
                    property_method::did_change, [weak_node](auto const &context) {
                        if (auto node = weak_node.lock()) {
                            node.subject().notify(node::method::renderer_changed, node);
                        }
                    });
                break;

            default:
                break;
        }

        if (observer) {
            _property_observers.emplace_back(std::move(observer));
        }
    }

    simd::float4x4 &local_matrix() {
        _update_local_matrix();
        return _local_matrix;
    }

    simd::float4x4 &matrix() {
        _update_matrix();
        return _matrix;
    }

    ui::point convert_position(ui::point const &loc) {
        auto const loc4 = simd::float4x4(matrix_invert(matrix())) * to_float4(loc.v);
        return {loc4.x, loc4.y};
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

    void _add_sub_node(ui::node &sub_node) {
        auto sub_node_impl = sub_node.impl_ptr<impl>();

        sub_node_impl->_parent_property.set_value(cast<ui::node>());
        sub_node_impl->_set_renderer_recursively(_renderer_property.value().lock());

        if (sub_node_impl->_subject.has_observer()) {
            sub_node_impl->_subject.notify(node::method::added_to_super, sub_node);
        }

        _set_updated(ui::node_update_reason::children);
    }

    void _remove_sub_node(ui::node const &sub_node) {
        auto sub_node_impl = sub_node.impl_ptr<impl>();

        sub_node_impl->_parent_property.set_value(ui::node{nullptr});
        sub_node_impl->_set_renderer_recursively(ui::renderer{nullptr});

        erase_if(_children, [&sub_node](ui::node const &node) { return node == sub_node; });

        if (sub_node_impl->_subject.has_observer()) {
            sub_node_impl->_subject.notify(node::method::removed_from_super, sub_node);
        }

        _set_updated(ui::node_update_reason::children);
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

    void _set_updated(ui::node_update_reason const reason) {
        _updates.set(reason);
    }

    void _update_local_matrix() {
        if (_updates.test(ui::node_update_reason::geometry)) {
            auto const &position = _position_property.value();
            auto const &angle = _angle_property.value();
            auto const &scale = _scale_property.value();
            _local_matrix = matrix::translation(position.x, position.y) * matrix::rotation(angle) *
                            matrix::scale(scale.width, scale.height);
        }
    }

    void _update_matrix() {
        if (auto locked_parent = _parent_property.value().lock()) {
            _matrix = locked_parent.matrix();
        } else {
            if (auto locked_renderer = renderer()) {
                _matrix = locked_renderer.projection_matrix();
            } else {
                _matrix = matrix_identity_float4x4;
            }
        }

        _update_local_matrix();

        _matrix = _matrix * _local_matrix;
    }
};

#pragma mark - node

ui::node::node() : base(std::make_shared<impl>()) {
    impl_ptr<impl>()->setup_observers();
}

ui::node::node(std::nullptr_t) : base(nullptr) {
}

ui::node::~node() = default;

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

simd::float4x4 const &ui::node::matrix() const {
    return impl_ptr<impl>()->matrix();
}

simd::float4x4 const &ui::node::local_matrix() const {
    return impl_ptr<impl>()->local_matrix();
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
    impl_ptr<impl>()->set_batch(std::move(batch));
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

void ui::node::dispatch_method(ui::node::method const method) {
    impl_ptr<impl>()->dispatch_method(method);
}

ui::point ui::node::convert_position(ui::point const &loc) const {
    return impl_ptr<impl>()->convert_position(loc);
}

void ui::node::attach_x_layout_guide(ui::layout_guide &guide) {
    auto observer = impl_ptr<impl>()->_position_property.subject().make_observer(
        property_method::did_change, [weak_guide = to_weak(guide)](auto const &context) {
            if (auto guide = weak_guide.lock()) {
                guide.set_value(context.value.new_value.x);
            }
        });

    guide.set_value_changed_handler([weak_node = to_weak(*this), observer = std::move(observer)](auto const value) {
        if (auto node = weak_node.lock()) {
            node.set_position({value, node.position().y});
        }
    });
}

void ui::node::attach_y_layout_guide(ui::layout_guide &guide) {
    auto observer = impl_ptr<impl>()->_position_property.subject().make_observer(
        property_method::did_change, [weak_guide = to_weak(guide)](auto const &context) {
            if (auto guide = weak_guide.lock()) {
                guide.set_value(context.value.new_value.y);
            }
        });

    guide.set_value_changed_handler([weak_node = to_weak(*this), observer = std::move(observer)](auto const value) {
        if (auto node = weak_node.lock()) {
            node.set_position({node.position().x, value});
        }
    });
}

void ui::node::attach_position_layout_guides(ui::layout_guide_point &point) {
    attach_x_layout_guide(point.x_guide());
    attach_y_layout_guide(point.y_guide());
}

std::string yas::to_string(ui::node::method const &method) {
    switch (method) {
        case ui::node::method::added_to_super:
            return "added_to_super";
        case ui::node::method::removed_from_super:
            return "removed_from_super";
        case ui::node::method::parent_changed:
            return "parent_changed";
        case ui::node::method::renderer_changed:
            return "renderer_changed";
        case ui::node::method::position_changed:
            return "position_changed";
        case ui::node::method::angle_changed:
            return "angle_changed";
        case ui::node::method::scale_changed:
            return "scale_changed";
        case ui::node::method::color_changed:
            return "color_changed";
        case ui::node::method::alpha_changed:
            return "alpha_changed";
        case ui::node::method::mesh_changed:
            return "mesh_changed";
        case ui::node::method::collider_changed:
            return "collider_changed";
        case ui::node::method::enabled_changed:
            return "enabled_changed";
    }
}

std::ostream &operator<<(std::ostream &os, yas::ui::node::method const &method) {
    os << to_string(method);
    return os;
}
