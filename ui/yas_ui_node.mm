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
#include "yas_ui_renderer.h"
#include "yas_ui_types.h"

using namespace yas;

#pragma mark - node::impl

struct ui::node::impl : public base::impl, public renderable_node::impl, public metal_object::impl {
   public:
    void prepare(ui::node &node) {
        auto weak_node = to_weak(node);

        // enabled

        auto enabled_observer = this->_enabled.chain().to_value(ui::node_update_reason::enabled);

        // geometry

        auto pos_chain = this->_position.chain().to_value(ui::node_update_reason::geometry);
        auto angle_chain = this->_angle.chain().to_value(ui::node_update_reason::geometry);
        auto scale_chain = this->_scale.chain().to_value(ui::node_update_reason::geometry);

        // mesh and mesh_color

        auto mesh_observer =
            this->_mesh.chain()
                .guard([weak_node](auto const &) { return !!weak_node; })
                .perform([weak_node](auto const &) { weak_node.lock().impl_ptr<impl>()->_update_mesh_color(); })
                .to_value(ui::node_update_reason::mesh);

        auto color_chain = this->_color.chain().to_null();
        auto alpha_chain = this->_alpha.chain().to_null();

        auto mesh_color_observer =
            color_chain.merge(std::move(alpha_chain))
                .guard([weak_node](auto const &) { return !!weak_node; })
                .perform([weak_node](auto const &) { weak_node.lock().impl_ptr<impl>()->_update_mesh_color(); })
                .end();

        // collider

        auto collider_chain = this->_collider.chain().to_value(ui::node_update_reason::collider);

        // batch

        auto batch_chain = this->_batch.chain().to_value(ui::node_update_reason::batch);

        // render_target

        auto render_target_chain = this->_render_target.chain().to_value(ui::node_update_reason::render_target);

        auto updates_observer = enabled_observer.merge(std::move(pos_chain))
                                    .merge(std::move(angle_chain))
                                    .merge(std::move(scale_chain))
                                    .merge(std::move(mesh_observer))
                                    .merge(std::move(collider_chain))
                                    .merge(std::move(batch_chain))
                                    .merge(std::move(render_target_chain))
                                    .perform([weak_node](ui::node_update_reason const &reason) {
                                        weak_node.lock().impl_ptr<impl>()->_set_updated(reason);
                                    })
                                    .end();

        this->_update_observers.reserve(2);
        this->_update_observers.emplace_back(std::move(mesh_color_observer));
        this->_update_observers.emplace_back(std::move(updates_observer));

        // dispatch

        this->_dispatch_receiver =
            chaining::perform_receiver<ui::node::method>([weak_node](ui::node::method const &method) {
                if (auto node = weak_node.lock()) {
                    node.impl_ptr<impl>()->_dispatch_sender.notify(std::make_pair(method, node));
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
        if (auto parent = this->_parent.raw().lock()) {
            parent.impl_ptr<impl>()->_remove_sub_node(cast<ui::node>());
        }
    }

    void set_batch(ui::batch &&batch) {
        if (batch) {
            batch.renderable().clear_render_meshes();
        }

        if (auto &old_batch = _batch.raw()) {
            old_batch.renderable().clear_render_meshes();
        }

        this->_batch.set_value(std::move(batch));
    }

    void build_render_info(ui::render_info &render_info) override {
        if (this->_enabled.raw()) {
            this->_update_local_matrix();

            this->_matrix = render_info.matrix * this->_local_matrix;
            auto const mesh_matrix = render_info.mesh_matrix * this->_local_matrix;

            if (auto &collider = this->_collider.raw()) {
                collider.renderable().set_matrix(this->_matrix);

                if (auto &detector = render_info.detector) {
                    auto &detector_updatable = detector.updatable();
                    if (detector_updatable.is_updating()) {
                        detector_updatable.push_front_collider(collider);
                    }
                }
            }

            if (auto &render_encodable = render_info.render_encodable) {
                if (auto &mesh = this->_mesh.raw()) {
                    mesh.renderable().set_matrix(mesh_matrix);
                    render_encodable.append_mesh(mesh);
                }

                if (auto &render_target = this->_render_target.raw()) {
                    auto &mesh = render_target.renderable().mesh();
                    mesh.renderable().set_matrix(mesh_matrix);
                    render_encodable.append_mesh(mesh);
                }
            }

            if (auto &render_target = this->_render_target.raw()) {
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
            } else if (auto &batch = _batch.raw()) {
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
        if (auto &mesh = this->_mesh.raw()) {
            if (auto ul = unless(mesh.metal().metal_setup(metal_system))) {
                return std::move(ul.value);
            }
        }

        if (auto &render_target = this->_render_target.raw()) {
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

        if (auto &batch = this->_batch.raw()) {
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
        return this->_renderer.raw().lock();
    }

    void set_renderer(ui::renderer &&renderer) override {
        this->_renderer.set_value(renderer);
    }

    void fetch_updates(ui::tree_updates &tree_updates) override {
        if (this->_enabled.raw()) {
            tree_updates.node_updates.flags |= this->_updates.flags;

            if (auto &mesh = this->_mesh.raw()) {
                tree_updates.mesh_updates.flags |= mesh.renderable().updates().flags;

                if (auto &mesh_data = mesh.mesh_data()) {
                    tree_updates.mesh_data_updates.flags |= mesh_data.renderable().updates().flags;
                }
            }

            if (auto &render_target = this->_render_target.raw()) {
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
        if (!this->_enabled.raw()) {
            return false;
        }

        for (auto &sub_node : this->_children) {
            if (sub_node.renderable().is_rendering_color_exists()) {
                return true;
            }
        }

        if (auto &mesh = this->_mesh.raw()) {
            return mesh.renderable().is_rendering_color_exists();
        }

        return false;
    }

    void clear_updates() override {
        if (this->_enabled.raw()) {
            this->_updates.flags.reset();

            if (auto &mesh = this->_mesh.raw()) {
                mesh.renderable().clear_updates();
            }

            if (auto &render_target = this->_render_target.raw()) {
                render_target.renderable().clear_updates();
            }

            for (auto &sub_node : this->_children) {
                sub_node.renderable().clear_updates();
            }
        } else {
            this->_updates.reset(ui::node_update_reason::enabled);
        }
    }

    chaining::chain_unsync_t<chain_pair_t> chain(std::vector<ui::node::method> const &methods) {
        for (auto const &method : methods) {
            if (this->_dispatch_observers.count(method) > 0) {
                continue;
            }

            chaining::any_observer_ptr observer = nullptr;

            switch (method) {
                case ui::node::method::added_to_super:
                case ui::node::method::removed_from_super:
                    observer = this->_notify_sender.chain()
                                   .guard([method](node::method const &value) { return method == value; })
                                   .send_to(*this->_dispatch_receiver)
                                   .end();
                    break;
            }

            this->_dispatch_observers.emplace(method, std::move(observer));
        }

        return this->_dispatch_sender.chain().guard(
            [methods](chain_pair_t const &pair) { return contains(methods, pair.first); });
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

    chaining::value::holder<weak<ui::node>> _parent{ui::node{nullptr}};
    chaining::value::holder<weak<ui::renderer>> _renderer{ui::renderer{nullptr}};

    chaining::value::holder<ui::point> _position{{.v = 0.0f}};
    chaining::value::holder<ui::angle> _angle{{0.0f}};
    chaining::value::holder<ui::size> _scale{{.v = 1.0f}};
    chaining::value::holder<ui::color> _color{{.v = 1.0f}};
    chaining::value::holder<float> _alpha{1.0f};
    chaining::value::holder<ui::mesh> _mesh{ui::mesh{nullptr}};
    chaining::value::holder<ui::collider> _collider{ui::collider{nullptr}};
    chaining::value::holder<ui::batch> _batch{ui::batch{nullptr}};
    chaining::value::holder<ui::render_target> _render_target{ui::render_target{nullptr}};
    chaining::value::holder<bool> _enabled{true};

    chaining::any_observer_ptr _x_observer = nullptr;
    chaining::any_observer_ptr _y_observer = nullptr;
    chaining::any_observer_ptr _position_observer = nullptr;

   private:
    std::vector<ui::node> _children;

    simd::float4x4 _matrix = matrix_identity_float4x4;
    simd::float4x4 _local_matrix = matrix_identity_float4x4;

    std::vector<chaining::any_observer_ptr> _update_observers;
    std::unordered_map<ui::node::method, chaining::any_observer_ptr> _dispatch_observers;
    chaining::notifier<chain_pair_t> _dispatch_sender;
    std::optional<chaining::perform_receiver<ui::node::method>> _dispatch_receiver = std::nullopt;
    chaining::notifier<ui::node::method> _notify_sender;

    node_updates_t _updates;

    void _add_sub_node(ui::node &sub_node) {
        auto sub_node_impl = sub_node.impl_ptr<impl>();

        sub_node_impl->_parent.set_value(cast<ui::node>());
        sub_node_impl->_set_renderer_recursively(this->_renderer.raw().lock());

        sub_node_impl->_notify_sender.notify(method::added_to_super);

        this->_set_updated(ui::node_update_reason::children);
    }

    void _remove_sub_node(ui::node const &sub_node) {
        auto sub_node_impl = sub_node.impl_ptr<impl>();

        sub_node_impl->_parent.set_value(ui::node{nullptr});
        sub_node_impl->_set_renderer_recursively(ui::renderer{nullptr});

        erase_if(this->_children, [&sub_node](ui::node const &node) { return node == sub_node; });

        sub_node_impl->_notify_sender.notify(method::removed_from_super);

        this->_set_updated(ui::node_update_reason::children);
    }

    void _set_renderer_recursively(ui::renderer const &renderer) {
        this->_renderer.set_value(renderer);

        for (auto &sub_node : this->_children) {
            sub_node.impl_ptr<impl>()->_set_renderer_recursively(renderer);
        }
    }

    void _update_mesh_color() {
        if (auto &mesh = this->_mesh.raw()) {
            auto const &color = this->_color.raw();
            auto const &alpha = this->_alpha.raw();
            mesh.set_color({color.red, color.green, color.blue, alpha});
        }
    }

    void _set_updated(ui::node_update_reason const reason) {
        this->_updates.set(reason);
    }

    void _update_local_matrix() {
        if (this->_updates.test(ui::node_update_reason::geometry)) {
            auto const &position = this->_position.raw();
            auto const &angle = this->_angle.raw();
            auto const &scale = this->_scale.raw();
            this->_local_matrix = matrix::translation(position.x, position.y) * matrix::rotation(angle.degrees) *
                                  matrix::scale(scale.width, scale.height);
        }
    }

    void _update_matrix() {
        if (auto locked_parent = this->_parent.raw().lock()) {
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

chaining::value::holder<ui::point> const &ui::node::position() const {
    return impl_ptr<impl>()->_position;
}

chaining::value::holder<ui::point> &ui::node::position() {
    return impl_ptr<impl>()->_position;
}

chaining::value::holder<ui::angle> const &ui::node::angle() const {
    return impl_ptr<impl>()->_angle;
}

chaining::value::holder<ui::angle> &ui::node::angle() {
    return impl_ptr<impl>()->_angle;
}

chaining::value::holder<ui::size> const &ui::node::scale() const {
    return impl_ptr<impl>()->_scale;
}

chaining::value::holder<ui::size> &ui::node::scale() {
    return impl_ptr<impl>()->_scale;
}

chaining::value::holder<ui::color> const &ui::node::color() const {
    return impl_ptr<impl>()->_color;
}

chaining::value::holder<ui::color> &ui::node::color() {
    return impl_ptr<impl>()->_color;
}

chaining::value::holder<float> const &ui::node::alpha() const {
    return impl_ptr<impl>()->_alpha;
}

chaining::value::holder<float> &ui::node::alpha() {
    return impl_ptr<impl>()->_alpha;
}

chaining::value::holder<bool> const &ui::node::is_enabled() const {
    return impl_ptr<impl>()->_enabled;
}

chaining::value::holder<bool> &ui::node::is_enabled() {
    return impl_ptr<impl>()->_enabled;
}

simd::float4x4 const &ui::node::matrix() const {
    return impl_ptr<impl>()->matrix();
}

simd::float4x4 const &ui::node::local_matrix() const {
    return impl_ptr<impl>()->local_matrix();
}

chaining::value::holder<ui::mesh> const &ui::node::mesh() const {
    return impl_ptr<impl>()->_mesh;
}

chaining::value::holder<ui::mesh> &ui::node::mesh() {
    return impl_ptr<impl>()->_mesh;
}

chaining::value::holder<ui::collider> const &ui::node::collider() const {
    return impl_ptr<impl>()->_collider;
}

chaining::value::holder<ui::collider> &ui::node::collider() {
    return impl_ptr<impl>()->_collider;
}

chaining::value::holder<ui::batch> const &ui::node::batch() const {
    return impl_ptr<impl>()->_batch;
}

chaining::value::holder<ui::batch> &ui::node::batch() {
    return impl_ptr<impl>()->_batch;
}

chaining::value::holder<ui::render_target> const &ui::node::render_target() const {
    return impl_ptr<impl>()->_render_target;
}

chaining::value::holder<ui::render_target> &ui::node::render_target() {
    return impl_ptr<impl>()->_render_target;
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
    return impl_ptr<impl>()->_parent.raw().lock();
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

chaining::chain_unsync_t<ui::node::chain_pair_t> ui::node::chain(ui::node::method const &method) const {
    return impl_ptr<impl>()->chain({method});
}

chaining::chain_unsync_t<ui::node::chain_pair_t> ui::node::chain(std::vector<ui::node::method> const &methods) const {
    return impl_ptr<impl>()->chain(methods);
}

chaining::chain_relayed_sync_t<ui::renderer, base::weak<ui::renderer>> ui::node::chain_renderer() const {
    return impl_ptr<impl>()->_renderer.chain().to([](weak<ui::renderer> const &weak_renderer) {
        if (auto renderer = weak_renderer.lock()) {
            return renderer;
        } else {
            return ui::renderer{nullptr};
        }
    });
}

chaining::chain_relayed_sync_t<ui::node, base::weak<ui::node>> ui::node::chain_parent() const {
    return impl_ptr<impl>()->_parent.chain().to([](weak<ui::node> const &weak_node) {
        if (auto node = weak_node.lock()) {
            return node;
        } else {
            return ui::node{nullptr};
        }
    });
}

ui::point ui::node::convert_position(ui::point const &loc) const {
    return impl_ptr<impl>()->convert_position(loc);
}

void ui::node::attach_x_layout_guide(ui::layout_guide &guide) {
    auto imp = impl_ptr<impl>();
    auto &position = imp->_position;
    auto weak_node = to_weak(*this);

    imp->_x_observer = guide.chain()
                           .guard([weak_node](float const &) { return !!weak_node; })
                           .to([weak_node](float const &x) {
                               return ui::point{x, weak_node.lock().position().raw().y};
                           })
                           .send_to(position)
                           .sync();

    imp->_position_observer = nullptr;
}

void ui::node::attach_y_layout_guide(ui::layout_guide &guide) {
    auto imp = impl_ptr<impl>();
    auto &position = imp->_position;
    auto weak_node = to_weak(*this);

    imp->_y_observer = guide.chain()
                           .guard([weak_node](float const &) { return !!weak_node; })
                           .to([weak_node](float const &y) {
                               return ui::point{weak_node.lock().position().raw().x, y};
                           })
                           .send_to(position)
                           .sync();

    imp->_position_observer = nullptr;
}

void ui::node::attach_position_layout_guides(ui::layout_guide_point &guide_point) {
    auto imp = impl_ptr<impl>();
    auto &position = imp->_position;
    auto weak_node = to_weak(*this);

    imp->_position_observer = guide_point.chain().send_to(position).sync();

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
