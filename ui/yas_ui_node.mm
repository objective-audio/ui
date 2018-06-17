//
//  yas_ui_node.mm
//

#include "yas_ui_angle.h"
#include "yas_ui_color.h"
#include "yas_ui_types.h"
// workaround for equation
#include "yas_property.h"
#include "yas_to_bool.h"
#include "yas_ui_batch.h"
#include "yas_ui_batch_protocol.h"
#include "yas_ui_collider.h"
#include "yas_ui_detector.h"
#include "yas_ui_effect.h"
#include "yas_ui_layout_guide.h"
#include "yas_ui_math.h"
#include "yas_ui_matrix.h"
#include "yas_ui_mesh.h"
#include "yas_ui_mesh_data.h"
#include "yas_ui_metal_encode_info.h"
#include "yas_ui_metal_system.h"
#include "yas_ui_node.h"
#include "yas_ui_render_info.h"
#include "yas_ui_render_target.h"
#include "yas_ui_renderer.h"
#include "yas_unless.h"

using namespace yas;

#pragma mark - node::impl

struct ui::node::impl : public base::impl, public renderable_node::impl, public metal_object::impl {
   public:
    void prepare(ui::node &node) {
        auto weak_node = to_weak(node);

        // enabled

        auto enabled_flow = this->_enabled_property.begin_value_flow().to_value(ui::node_update_reason::enabled);

        // geometry

        auto pos_flow = this->_position_property.begin_value_flow().to_value(ui::node_update_reason::geometry);
        auto angle_flow = this->_angle_property.begin_value_flow().to_value(ui::node_update_reason::geometry);
        auto scale_flow = this->_scale_property.begin_value_flow().to_value(ui::node_update_reason::geometry);

        // mesh and mesh_color

        auto mesh_flow =
            this->_mesh_property.begin_value_flow()
                .filter([weak_node](auto const &) { return !!weak_node; })
                .perform([weak_node](auto const &) { weak_node.lock().impl_ptr<impl>()->_update_mesh_color(); })
                .to_value(ui::node_update_reason::mesh)
                .normalize();

        auto color_flow = this->_color_property.begin_value_flow().to_null();
        auto alpha_flow = this->_alpha_property.begin_value_flow().to_null();

        auto mesh_color_flow =
            color_flow.merge(alpha_flow)
                .filter([weak_node](auto const &) { return !!weak_node; })
                .perform([weak_node](auto const &) { weak_node.lock().impl_ptr<impl>()->_update_mesh_color(); })
                .end();

        // collider

        auto collider_flow = this->_collider_property.begin_value_flow().to_value(ui::node_update_reason::collider);

        // batch

        auto batch_flow = this->_batch_property.begin_value_flow().to_value(ui::node_update_reason::batch);

        // render_target

        auto render_target_flow =
            this->_render_target_property.begin_value_flow().to_value(ui::node_update_reason::render_target);

        auto updates_flow = enabled_flow.merge(pos_flow)
                                .merge(angle_flow)
                                .merge(scale_flow)
                                .merge(mesh_flow)
                                .merge(collider_flow)
                                .merge(batch_flow)
                                .merge(render_target_flow)
                                .perform([weak_node](ui::node_update_reason const &reason) {
                                    weak_node.lock().impl_ptr<impl>()->_set_updated(reason);
                                })
                                .end();

        this->_update_flows.reserve(2);
        this->_update_flows.emplace_back(std::move(mesh_color_flow));
        this->_update_flows.emplace_back(std::move(updates_flow));

        // dispatch

        this->_dispatch_receiver = flow::receiver<ui::node::method>([weak_node](ui::node::method const &method) {
            if (auto node = weak_node.lock()) {
                node.impl_ptr<impl>()->_dispatch_sender.send_value(std::make_pair(method, node));
            }
        });
    }

    std::vector<ui::node> &children() {
        return this->_children;
    }

    void add_sub_node(ui::node &&sub_node) {
        sub_node.remove_from_super_node();
        this->_children.emplace_back(std::move(sub_node));
        this->_add_sub_node(this->_children.back());
    }

    void add_sub_node(ui::node &&sub_node, std::size_t const idx) {
        sub_node.remove_from_super_node();
        auto iterator = this->_children.emplace(this->_children.begin() + idx, std::move(sub_node));
        this->_add_sub_node(*iterator);
    }

    void remove_from_super_node() {
        if (auto parent = this->_parent_property.value().lock()) {
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

        this->_batch_property.set_value(std::move(batch));
    }

    void build_render_info(ui::render_info &render_info) override {
        if (this->_enabled_property.value()) {
            this->_update_local_matrix();

            this->_matrix = render_info.matrix * this->_local_matrix;
            auto const mesh_matrix = render_info.mesh_matrix * this->_local_matrix;

            if (auto &collider = this->_collider_property.value()) {
                collider.renderable().set_matrix(this->_matrix);

                if (auto &detector = render_info.detector) {
                    auto &detector_updatable = detector.updatable();
                    if (detector_updatable.is_updating()) {
                        detector_updatable.push_front_collider(collider);
                    }
                }
            }

            if (auto &render_encodable = render_info.render_encodable) {
                if (auto &mesh = this->_mesh_property.value()) {
                    mesh.renderable().set_matrix(mesh_matrix);
                    render_encodable.append_mesh(mesh);
                }

                if (auto &render_target = this->_render_target_property.value()) {
                    auto &mesh = render_target.renderable().mesh();
                    mesh.renderable().set_matrix(mesh_matrix);
                    render_encodable.append_mesh(mesh);
                }
            }

            if (auto &render_target = this->_render_target_property.value()) {
                bool needs_render = this->_updates.test(ui::node_update_reason::render_target);

                if (!needs_render) {
                    needs_render = render_target.renderable().updates().flags.any();
                }

                auto &renderable = render_target.renderable();
                auto &effect = renderable.effect();
                if (!needs_render && effect) {
                    needs_render = effect.renderable().updates().flags.any();
                }

                if (!needs_render) {
                    ui::tree_updates tree_updates;

                    for (auto &sub_node : this->_children) {
                        sub_node.renderable().fetch_updates(tree_updates);
                    }

                    needs_render = tree_updates.is_any_updated();
                }

                if (needs_render) {
                    auto &stackable = render_info.render_stackable;

                    if (render_target.renderable().push_encode_info(stackable)) {
                        ui::render_info target_render_info{.render_encodable = render_info.render_encodable,
                                                           .render_effectable = render_info.render_effectable,
                                                           .render_stackable = render_info.render_stackable,
                                                           .detector = render_info.detector};

                        auto &projection_matrix = renderable.projection_matrix();
                        simd::float4x4 const matrix = projection_matrix * this->_matrix;
                        simd::float4x4 const mesh_matrix = projection_matrix;
                        for (auto &sub_node : this->_children) {
                            target_render_info.matrix = matrix;
                            target_render_info.mesh_matrix = mesh_matrix;
                            sub_node.impl_ptr<impl>()->build_render_info(target_render_info);
                        }

                        if (effect) {
                            render_info.render_effectable.append_effect(effect);
                        }

                        stackable.pop_encode_info();
                    }
                }
            } else if (auto &batch = _batch_property.value()) {
                ui::tree_updates tree_updates;

                for (auto &sub_node : this->_children) {
                    sub_node.renderable().fetch_updates(tree_updates);
                }

                auto const building_type = tree_updates.batch_building_type();

                ui::render_info batch_render_info{.detector = render_info.detector};
                auto &batch_renderable = batch.renderable();

                if (to_bool(building_type)) {
                    batch_render_info.render_encodable = batch.encodable();
                    batch_renderable.begin_render_meshes_building(building_type);
                }

                for (auto &sub_node : this->_children) {
                    batch_render_info.matrix = this->_matrix;
                    batch_render_info.mesh_matrix = matrix_identity_float4x4;
                    sub_node.impl_ptr<impl>()->build_render_info(batch_render_info);
                }

                if (to_bool(building_type)) {
                    batch_renderable.commit_render_meshes_building();
                }

                for (auto &mesh : batch_renderable.meshes()) {
                    mesh.renderable().set_matrix(mesh_matrix);
                    render_info.render_encodable.append_mesh(mesh);
                }
            } else {
                for (auto &sub_node : this->_children) {
                    render_info.matrix = this->_matrix;
                    render_info.mesh_matrix = mesh_matrix;
                    sub_node.impl_ptr<impl>()->build_render_info(render_info);
                }
            }
        }
    }

    ui::setup_metal_result metal_setup(ui::metal_system const &metal_system) override {
        if (auto &mesh = this->_mesh_property.value()) {
            if (auto ul = unless(mesh.metal().metal_setup(metal_system))) {
                return std::move(ul.value);
            }
        }

        if (auto &render_target = this->_render_target_property.value()) {
            if (auto ul = unless(render_target.metal().metal_setup(metal_system))) {
                return std::move(ul.value);
            }

            if (auto ul = unless(render_target.renderable().mesh().metal().metal_setup(metal_system))) {
                return std::move(ul.value);
            }

            if (auto &effect = render_target.renderable().effect()) {
                if (auto ul = unless(effect.metal().metal_setup(metal_system))) {
                    return std::move(ul.value);
                }
            }
        }

        if (auto &batch = this->_batch_property.value()) {
            if (auto ul = unless(batch.metal().metal_setup(metal_system))) {
                return std::move(ul.value);
            }
        }

        for (auto &sub_node : this->_children) {
            if (auto ul = unless(sub_node.metal().metal_setup(metal_system))) {
                return std::move(ul.value);
            }
        }

        return ui::setup_metal_result{nullptr};
    }

    ui::renderer renderer() override {
        return this->_renderer_property.value().lock();
    }

    void set_renderer(ui::renderer &&renderer) override {
        this->_renderer_property.set_value(renderer);
    }

    void fetch_updates(ui::tree_updates &tree_updates) override {
        if (this->_enabled_property.value()) {
            tree_updates.node_updates.flags |= this->_updates.flags;

            if (auto &mesh = this->_mesh_property.value()) {
                tree_updates.mesh_updates.flags |= mesh.renderable().updates().flags;

                if (auto &mesh_data = mesh.mesh_data()) {
                    tree_updates.mesh_data_updates.flags |= mesh_data.renderable().updates().flags;
                }
            }

            if (auto &render_target = this->_render_target_property.value()) {
                tree_updates.render_target_updates.flags |= render_target.renderable().updates().flags;

                auto &renderable = render_target.renderable();
                auto &mesh = renderable.mesh();

                tree_updates.mesh_updates.flags |= mesh.renderable().updates().flags;

                if (auto &mesh_data = mesh.mesh_data()) {
                    tree_updates.mesh_data_updates.flags |= mesh_data.renderable().updates().flags;
                }

                if (auto &effect = renderable.effect()) {
                    tree_updates.effect_updates.flags |= effect.renderable().updates().flags;
                }
            }

            for (auto &sub_node : this->_children) {
                sub_node.renderable().fetch_updates(tree_updates);
            }
        } else if (this->_updates.test(ui::node_update_reason::enabled)) {
            tree_updates.node_updates.set(ui::node_update_reason::enabled);
        }
    }

    bool is_rendering_color_exists() override {
        if (!this->_enabled_property.value()) {
            return false;
        }

        for (auto &sub_node : this->_children) {
            if (sub_node.renderable().is_rendering_color_exists()) {
                return true;
            }
        }

        if (auto &mesh = this->_mesh_property.value()) {
            return mesh.renderable().is_rendering_color_exists();
        }

        return false;
    }

    void clear_updates() override {
        if (this->_enabled_property.value()) {
            this->_updates.flags.reset();

            if (auto &mesh = this->_mesh_property.value()) {
                mesh.renderable().clear_updates();
            }

            if (auto &render_target = this->_render_target_property.value()) {
                render_target.renderable().clear_updates();
            }

            for (auto &sub_node : this->_children) {
                sub_node.renderable().clear_updates();
            }
        } else {
            this->_updates.reset(ui::node_update_reason::enabled);
        }
    }

    flow::node_t<flow_pair_t, false> begin_flow(std::vector<ui::node::method> const &methods) {
        for (auto const &method : methods) {
            if (this->_dispatch_flows.count(method) > 0) {
                continue;
            }

            flow::observer flow = nullptr;

            switch (method) {
                case ui::node::method::added_to_super:
                case ui::node::method::removed_from_super:
                    flow = this->_notify_sender.begin()
                               .filter([method](node::method const &value) { return method == value; })
                               .receive(this->_dispatch_receiver)
                               .end();
                    break;
            }

            this->_dispatch_flows.emplace(method, std::move(flow));
        }

        return this->_dispatch_sender.begin().filter(
            [methods](flow_pair_t const &pair) { return contains(methods, pair.first); });
    }

    simd::float4x4 &local_matrix() {
        this->_update_local_matrix();
        return this->_local_matrix;
    }

    simd::float4x4 &matrix() {
        this->_update_matrix();
        return this->_matrix;
    }

    ui::point convert_position(ui::point const &loc) {
        auto const loc4 = simd::float4x4(matrix_invert(this->matrix())) * to_float4(loc.v);
        return {loc4.x, loc4.y};
    }

    property<weak<ui::node>> _parent_property{{.value = ui::node{nullptr}}};
    property<weak<ui::renderer>> _renderer_property{{.value = ui::renderer{nullptr}}};

    property<ui::point> _position_property{{.value = 0.0f}};
    property<ui::angle> _angle_property{{.value = 0.0f}};
    property<ui::size> _scale_property{{.value = {.v = 1.0f}}};
    property<ui::color> _color_property{{.value = {.v = 1.0f}}};
    property<float> _alpha_property{{.value = 1.0f}};
    property<ui::mesh> _mesh_property{{.value = nullptr}};
    property<ui::collider> _collider_property{{.value = nullptr}};
    property<ui::batch> _batch_property{{.value = nullptr}};
    property<ui::render_target> _render_target_property{{.value = nullptr}};
    property<bool> _enabled_property{{.value = true}};

    flow::observer _x_observer = nullptr;
    flow::observer _y_observer = nullptr;
    flow::observer _position_observer = nullptr;

   private:
    std::vector<ui::node> _children;

    simd::float4x4 _matrix = matrix_identity_float4x4;
    simd::float4x4 _local_matrix = matrix_identity_float4x4;

    std::vector<flow::observer> _update_flows;
    std::unordered_map<ui::node::method, flow::observer> _dispatch_flows;
    flow::sender<flow_pair_t> _dispatch_sender;
    flow::receiver<ui::node::method> _dispatch_receiver = nullptr;
    flow::sender<ui::node::method> _notify_sender;

    node_updates_t _updates;

    void _add_sub_node(ui::node &sub_node) {
        auto sub_node_impl = sub_node.impl_ptr<impl>();

        sub_node_impl->_parent_property.set_value(cast<ui::node>());
        sub_node_impl->_set_renderer_recursively(this->_renderer_property.value().lock());

        sub_node_impl->_notify_sender.send_value(method::added_to_super);

        this->_set_updated(ui::node_update_reason::children);
    }

    void _remove_sub_node(ui::node const &sub_node) {
        auto sub_node_impl = sub_node.impl_ptr<impl>();

        sub_node_impl->_parent_property.set_value(ui::node{nullptr});
        sub_node_impl->_set_renderer_recursively(ui::renderer{nullptr});

        erase_if(this->_children, [&sub_node](ui::node const &node) { return node == sub_node; });

        sub_node_impl->_notify_sender.send_value(method::removed_from_super);

        this->_set_updated(ui::node_update_reason::children);
    }

    void _set_renderer_recursively(ui::renderer const &renderer) {
        this->_renderer_property.set_value(renderer);

        for (auto &sub_node : this->_children) {
            sub_node.impl_ptr<impl>()->_set_renderer_recursively(renderer);
        }
    }

    void _update_mesh_color() {
        if (auto &mesh = this->_mesh_property.value()) {
            auto const &color = this->_color_property.value();
            auto const &alpha = this->_alpha_property.value();
            mesh.set_color({color.red, color.green, color.blue, alpha});
        }
    }

    void _set_updated(ui::node_update_reason const reason) {
        this->_updates.set(reason);
    }

    void _update_local_matrix() {
        if (this->_updates.test(ui::node_update_reason::geometry)) {
            auto const &position = this->_position_property.value();
            auto const &angle = this->_angle_property.value();
            auto const &scale = this->_scale_property.value();
            this->_local_matrix = matrix::translation(position.x, position.y) * matrix::rotation(angle.degrees) *
                                  matrix::scale(scale.width, scale.height);
        }
    }

    void _update_matrix() {
        if (auto locked_parent = this->_parent_property.value().lock()) {
            this->_matrix = locked_parent.matrix();
        } else {
            if (auto locked_renderer = this->renderer()) {
                this->_matrix = locked_renderer.projection_matrix();
            } else {
                this->_matrix = matrix_identity_float4x4;
            }
        }

        this->_update_local_matrix();

        this->_matrix = this->_matrix * this->_local_matrix;
    }
};

#pragma mark - node

ui::node::node() : base(std::make_shared<impl>()) {
    impl_ptr<impl>()->prepare(*this);
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

ui::angle ui::node::angle() const {
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

ui::render_target const &ui::node::render_target() const {
    return impl_ptr<impl>()->_render_target_property.value();
}

ui::render_target &ui::node::render_target() {
    return impl_ptr<impl>()->_render_target_property.value();
}

void ui::node::set_position(ui::point point) {
    impl_ptr<impl>()->_position_property.set_value(std::move(point));
}

void ui::node::set_angle(ui::angle angle) {
    impl_ptr<impl>()->_angle_property.set_value(std::move(angle));
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

void ui::node::set_render_target(ui::render_target render_target) {
    impl_ptr<impl>()->_render_target_property.set_value(std::move(render_target));
}

void ui::node::set_enabled(bool const enabled) {
    impl_ptr<impl>()->_enabled_property.set_value(enabled);
}

void ui::node::add_sub_node(ui::node sub_node) {
    impl_ptr<impl>()->add_sub_node(std::move(sub_node));
}

void ui::node::add_sub_node(ui::node sub_node, std::size_t const idx) {
    impl_ptr<impl>()->add_sub_node(std::move(sub_node), idx);
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
    if (!this->_metal_object) {
        this->_metal_object = ui::metal_object{impl_ptr<ui::metal_object::impl>()};
    }
    return this->_metal_object;
}

ui::renderable_node &ui::node::renderable() {
    if (!this->_renderable) {
        this->_renderable = ui::renderable_node{impl_ptr<ui::renderable_node::impl>()};
    }
    return this->_renderable;
}

flow::node_t<ui::node::flow_pair_t, false> ui::node::begin_flow(ui::node::method const &method) const {
    return impl_ptr<impl>()->begin_flow({method});
}

flow::node_t<ui::node::flow_pair_t, false> ui::node::begin_flow(std::vector<ui::node::method> const &methods) const {
    return impl_ptr<impl>()->begin_flow(methods);
}

flow::node<ui::renderer, weak<ui::renderer>, weak<ui::renderer>, true> ui::node::begin_renderer_flow() const {
    return impl_ptr<impl>()->_renderer_property.begin_value_flow().map([](weak<ui::renderer> const &weak_renderer) {
        if (auto renderer = weak_renderer.lock()) {
            return renderer;
        } else {
            return ui::renderer{nullptr};
        }
    });
}

flow::node<ui::node, weak<ui::node>, weak<ui::node>, true> ui::node::begin_parent_flow() const {
    return impl_ptr<impl>()->_parent_property.begin_value_flow().map([](weak<ui::node> const &weak_node) {
        if (auto node = weak_node.lock()) {
            return node;
        } else {
            return ui::node{nullptr};
        }
    });
}

flow::node_t<ui::point, true> ui::node::begin_position_flow() const {
    return impl_ptr<impl>()->_position_property.begin_value_flow();
}

flow::node_t<ui::angle, true> ui::node::begin_angle_flow() const {
    return impl_ptr<impl>()->_angle_property.begin_value_flow();
}

flow::node_t<ui::size, true> ui::node::begin_scale_flow() const {
    return impl_ptr<impl>()->_scale_property.begin_value_flow();
}

flow::node_t<ui::color, true> ui::node::begin_color_flow() const {
    return impl_ptr<impl>()->_color_property.begin_value_flow();
}

flow::node_t<float, true> ui::node::begin_alpha_flow() const {
    return impl_ptr<impl>()->_alpha_property.begin_value_flow();
}

flow::node_t<ui::mesh, true> ui::node::begin_mesh_flow() const {
    return impl_ptr<impl>()->_mesh_property.begin_value_flow();
}

flow::node_t<ui::collider, true> ui::node::begin_collider_flow() const {
    return impl_ptr<impl>()->_collider_property.begin_value_flow();
}

flow::node_t<bool, true> ui::node::begin_enabled_flow() const {
    return impl_ptr<impl>()->_enabled_property.begin_value_flow();
}

ui::point ui::node::convert_position(ui::point const &loc) const {
    return impl_ptr<impl>()->convert_position(loc);
}

void ui::node::attach_x_layout_guide(ui::layout_guide &guide) {
    auto imp = impl_ptr<impl>();
    auto &position = imp->_position_property;
    auto weak_node = to_weak(*this);

    imp->_x_observer = guide.begin_flow()
                           .filter([weak_node](float const &) { return !!weak_node; })
                           .map([weak_node](float const &x) {
                               return ui::point{x, weak_node.lock().position().y};
                           })
                           .receive(position.receiver())
                           .sync();

    imp->_position_observer = nullptr;
}

void ui::node::attach_y_layout_guide(ui::layout_guide &guide) {
    auto imp = impl_ptr<impl>();
    auto &position = imp->_position_property;
    auto weak_node = to_weak(*this);

    imp->_y_observer = guide.begin_flow()
                           .filter([weak_node](float const &) { return !!weak_node; })
                           .map([weak_node](float const &y) {
                               return ui::point{weak_node.lock().position().x, y};
                           })
                           .receive(position.receiver())
                           .sync();

    imp->_position_observer = nullptr;
}

void ui::node::attach_position_layout_guides(ui::layout_guide_point &guide_point) {
    auto imp = impl_ptr<impl>();
    auto &position = imp->_position_property;
    auto weak_node = to_weak(*this);

    imp->_position_observer = guide_point.begin_flow().receive(position.receiver()).sync();

    imp->_x_observer = nullptr;
    imp->_y_observer = nullptr;
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
