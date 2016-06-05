//
//  yas_ui_node.mm
//

#include <bitset>
#include "yas_observing.h"
#include "yas_property.h"
#include "yas_ui_batch.h"
#include "yas_ui_batch_protocol.h"
#include "yas_ui_collider.h"
#include "yas_ui_collision_detector.h"
#include "yas_ui_matrix.h"
#include "yas_ui_mesh.h"
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
        _update_reasons.set();
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

        sub_node_impl->parent_property.set_value(cast<ui::node>());
        sub_node_impl->_set_renderer_recursively(renderer_property.value().lock());

        if (sub_node_impl->subject.has_observer()) {
            sub_node_impl->subject.notify(node_method::added_to_super, sub_node);
        }

        if (auto renderer = renderer_property.value().lock()) {
            _set_updated_for_collider(ui::collider_update_reason::existence);
        }
    }

    void remove_sub_node(ui::node const &sub_node) {
        auto sub_node_impl = sub_node.impl_ptr<impl>();

        sub_node_impl->parent_property.set_value(ui::node{nullptr});
        sub_node_impl->_set_renderer_recursively(ui::renderer{nullptr});

        erase_if(_children, [&sub_node](ui::node const &node) { return node == sub_node; });

        if (sub_node_impl->subject.has_observer()) {
            sub_node_impl->subject.notify(node_method::removed_from_super, sub_node);
        }

        if (auto renderer = renderer_property.value().lock()) {
            _set_updated_for_collider(ui::collider_update_reason::existence);
        }
    }

    void remove_from_super_node() {
        if (auto parent = parent_property.value().lock()) {
            parent.impl_ptr<impl>()->remove_sub_node(cast<ui::node>());
        }
    }

    void update_render_info(ui::render_info &render_info) override {
        auto const is_geometry_updated = _is_updated(ui::node_update_reason::geometry);
        _update_reasons.reset();

        if (!enabled_property.value()) {
            return;
        }

        if (is_geometry_updated) {
            auto const &position = position_property.value();
            auto const &angle = angle_property.value();
            auto const &scale = scale_property.value();
            _local_matrix = matrix::translation(position.x, position.y) * matrix::rotation(angle) *
                            matrix::scale(scale.width, scale.height);
        }

        _matrix = render_info.matrix * _local_matrix;
        auto const mesh_matrix = render_info.mesh_matrix * _local_matrix;

        if (auto &collider = collider_property.value()) {
            collider.renderable().set_matrix(_matrix);
            render_info.collision_detector.updatable().push_front_collider_if_needed(collider);
        }

        if (auto &render_encodable = render_info.render_encodable) {
            if (auto &mesh = mesh_property.value()) {
                mesh.renderable().set_matrix(mesh_matrix);
                render_encodable.push_back_mesh(mesh);
            }
        }

        if (auto batch = batch_property.value()) {
            ui::render_info batch_render_info;
            batch_render_info.collision_detector = render_info.collision_detector;
            auto &batch_renderable = batch.renderable();

            bool is_children_updated = false;
            for (auto &sub_node : _children) {
                if (sub_node.renderable().needs_update_for_render()) {
                    is_children_updated = true;
                    break;
                }
            }

            if (is_children_updated) {
                batch_render_info.render_encodable = batch.encodable();
                batch_renderable.clear();
            }

            for (auto &sub_node : _children) {
                batch_render_info.matrix = _matrix;
                batch_render_info.mesh_matrix = matrix_identity_float4x4;
                sub_node.impl_ptr<impl>()->update_render_info(batch_render_info);
            }

            if (is_children_updated) {
                batch_renderable.commit();
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
                sub_node.impl_ptr<impl>()->update_render_info(render_info);
            }
        }
    }

    ui::setup_metal_result metal_setup(id<MTLDevice> const device) override {
        if (auto &mesh = mesh_property.value()) {
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
        return renderer_property.value().lock();
    }

    void set_renderer(ui::renderer &&renderer) override {
        renderer_property.set_value(renderer);
    }

    bool needs_update_for_render() override {
        if (_update_reasons.any()) {
            return true;
        }

        if (!enabled_property.value()) {
            return false;
        }

        if (auto &mesh = mesh_property.value()) {
            if (mesh.renderable().needs_update_for_render()) {
                return true;
            }
        }

        for (auto &sub_node : _children) {
            if (sub_node.renderable().needs_update_for_render()) {
                return true;
            }
        }

        return false;
    }

    ui::point convert_position(ui::point const &loc) {
        auto const loc4 = simd::float4x4(matrix_invert(_matrix)) * simd::float4{loc.x, loc.y, 0.0f, 0.0f};
        return {loc4.x, loc4.y};
    }

    void _set_renderer_recursively(ui::renderer const &renderer) {
        renderer_property.set_value(renderer);

        for (auto &sub_node : _children) {
            sub_node.impl_ptr<impl>()->_set_renderer_recursively(renderer);
        }
    }

    void _update_mesh_color() {
        if (auto &mesh = mesh_property.value()) {
            auto const &color = color_property.value();
            auto const &alpha = alpha_property.value();
            mesh.set_color({color.red, color.green, color.blue, alpha});
        }
    }

    void _set_updated_for_collider(ui::collider_update_reason const reason) {
        if (auto locked_renderer = renderer()) {
            locked_renderer.collision_detector().updatable().set_needs_update(reason);
        }
    }

    bool _is_updated(ui::node_update_reason const reason) {
        return _update_reasons.test(static_cast<ui::node_update_reason_t>(reason));
    }

    void _set_updated(ui::node_update_reason const reason) {
        _update_reasons.set(static_cast<ui::node_update_reason_t>(reason));
    }

    property<weak<ui::node>> parent_property{{.value = ui::node{nullptr}}};
    property<weak<ui::renderer>> renderer_property{{.value = ui::renderer{nullptr}}};

    property<ui::point> position_property{{.value = 0.0f}};
    property<float> angle_property{{.value = 0.0f}};
    property<ui::size> scale_property{{.value = 1.0f}};
    property<ui::color> color_property{{.value = 1.0f}};
    property<float> alpha_property{{.value = 1.0f}};
    property<ui::mesh> mesh_property{{.value = nullptr}};
    property<ui::collider> collider_property{{.value = nullptr}};
    property<ui::batch> batch_property{{.value = nullptr}};
    property<bool> enabled_property{{.value = true}};

    node::subject_t subject;
    std::vector<base> _property_observers;

   private:
    std::vector<ui::node> _children;

    simd::float4x4 _matrix = matrix_identity_float4x4;
    simd::float4x4 _local_matrix = matrix_identity_float4x4;

    std::bitset<ui::node_update_reason_count> _update_reasons;
};

#pragma mark - node

ui::node::node() : base(std::make_shared<impl>()) {
    auto imp_ptr = impl_ptr<impl>();
    auto &observers = imp_ptr->_property_observers;
    auto weak_node = to_weak(*this);

    observers.reserve(9);

    observers.emplace_back(
        imp_ptr->enabled_property.subject().make_observer(property_method::did_change, [weak_node](auto const &) {
            if (auto node = weak_node.lock()) {
                auto imp_ptr = node.impl_ptr<impl>();
                imp_ptr->_set_updated(ui::node_update_reason::enabled);
                imp_ptr->_set_updated_for_collider(ui::collider_update_reason::existence);
            }
        }));

    observers.emplace_back(
        imp_ptr->position_property.subject().make_observer(property_method::did_change, [weak_node](auto const &) {
            if (auto node = weak_node.lock()) {
                node.impl_ptr<impl>()->_set_updated(ui::node_update_reason::geometry);
            }
        }));

    observers.emplace_back(
        imp_ptr->angle_property.subject().make_observer(property_method::did_change, [weak_node](auto const &) {
            if (auto node = weak_node.lock()) {
                node.impl_ptr<impl>()->_set_updated(ui::node_update_reason::geometry);
            }
        }));

    observers.emplace_back(
        imp_ptr->scale_property.subject().make_observer(property_method::did_change, [weak_node](auto const &) {
            if (auto node = weak_node.lock()) {
                node.impl_ptr<impl>()->_set_updated(ui::node_update_reason::geometry);
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
                node.impl_ptr<impl>()->_set_updated_for_collider(ui::collider_update_reason::existence);
            }
        }));

    observers.emplace_back(
        imp_ptr->batch_property.subject().make_observer(property_method::did_change, [weak_node](auto const &) {
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

ui::batch const &ui::node::batch() const {
    return impl_ptr<impl>()->batch_property.value();
}

ui::batch &ui::node::batch() {
    return impl_ptr<impl>()->batch_property.value();
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

void ui::node::set_batch(ui::batch batch) {
    if (batch) {
        batch.renderable().clear();
    }
    impl_ptr<impl>()->batch_property.set_value(std::move(batch));
}

void ui::node::set_enabled(bool const enabled) {
    impl_ptr<impl>()->enabled_property.set_value(enabled);
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
    return impl_ptr<impl>()->parent_property.value().lock();
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
            observer = imp_ptr->renderer_property.subject().make_observer(
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
