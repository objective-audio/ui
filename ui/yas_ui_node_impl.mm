//
//  yas_ui_node_impl.mm
//

#include "yas_stl_utils.h"
#include "yas_ui_encode_info.h"
#include "yas_ui_matrix.h"
#include "yas_ui_mesh.h"
#include "yas_ui_node.h"
#include "yas_ui_render_info.h"
#include "yas_ui_renderer.h"
#include "yas_unless.h"

using namespace yas;

ui::node::impl::impl() = default;
ui::node::impl::~impl() = default;

std::vector<ui::node> const &ui::node::impl::children() {
    return _children;
}

void ui::node::impl::add_sub_node(ui::node &&sub_node) {
    auto sub_node_impl = sub_node.impl_ptr<impl>();

    _children.emplace_back(std::move(sub_node));

    sub_node_impl->parent_property.set_value(cast<ui::node>());
    sub_node_impl->_set_node_renderer_recursively(node_renderer_property.value().lock());

    if (sub_node_impl->subject.has_observer()) {
        sub_node_impl->subject.notify(node_method::add_to_super, sub_node);
    }
}

void ui::node::impl::remove_sub_node(ui::node const &sub_node) {
    auto sub_node_impl = sub_node.impl_ptr<impl>();

    sub_node_impl->parent_property.set_value(ui::node{nullptr});
    sub_node_impl->_set_node_renderer_recursively(ui::node_renderer{nullptr});

    erase_if(_children, [&sub_node](ui::node const &node) { return node == sub_node; });

    if (sub_node_impl->subject.has_observer()) {
        sub_node_impl->subject.notify(node_method::remove_from_super, sub_node);
    }
}

void ui::node::impl::remove_from_super_node() {
    if (auto parent = parent_property.value().lock()) {
        parent.impl_ptr<impl>()->remove_sub_node(cast<ui::node>());
    }
}

void ui::node::impl::update_render_info(render_info &render_info) {
    if (!enabled_property.value()) {
        return;
    }

    if (_needs_update_matrix) {
        auto const &position = position_property.value();
        auto const &angle = angle_property.value();
        auto const &scale = scale_property.value();
        _local_matrix =
            matrix::translation(position.x, position.y) * matrix::rotation(angle) * matrix::scale(scale.w, scale.h);
        _needs_update_matrix = false;
    }

    _render_matrix = render_info.render_matrix * _local_matrix;

    if (auto &mesh = mesh_property.value()) {
        mesh.renderable().set_matrix(_render_matrix);
        if (auto encode_info = render_info.current_encode_info()) {
            encode_info.push_back_mesh(mesh);
        }
    }

    if (auto &collider = collider_property.value()) {
        collider.renderable().set_matrix(_render_matrix);
        render_info.collision_detector.updatable().push_front_collider(collider);
    }

    for (auto &sub_node : _children) {
        render_info.render_matrix = _render_matrix;
        sub_node.impl_ptr<impl>()->update_render_info(render_info);
    }
}

ui::setup_metal_result ui::node::impl::setup(id<MTLDevice> const device) {
    if (auto &mesh = mesh_property.value()) {
        if (auto ul = unless(mesh.metal().setup(device))) {
            return std::move(ul.value);
        }
    }

    for (auto &sub_node : _children) {
        if (auto ul = unless(sub_node.metal().setup(device))) {
            return std::move(ul.value);
        }
    }

    return ui::setup_metal_result{nullptr};
}

ui::node_renderer ui::node::impl::renderer() {
    return node_renderer_property.value().lock();
}

void ui::node::impl::set_renderer(ui::node_renderer &&renderer) {
    node_renderer_property.set_value(renderer);
}

simd::float2 ui::node::impl::convert_position(simd::float2 const &loc) {
    auto const loc4 = simd::float4x4(matrix_invert(_render_matrix)) * simd::float4{loc.x, loc.y, 0.0f, 0.0f};
    return {loc4.x, loc4.y};
}

void ui::node::impl::_set_node_renderer_recursively(ui::node_renderer const &renderer) {
    node_renderer_property.set_value(renderer);

    for (auto &sub_node : _children) {
        sub_node.impl_ptr<impl>()->_set_node_renderer_recursively(renderer);
    }
}

void ui::node::impl::_udpate_mesh_color() {
    if (auto &mesh = mesh_property.value()) {
        auto const &color = color_property.value().v;
        auto const &alpha = alpha_property.value();
        mesh.set_color({color[0] * alpha, color[1] * alpha, color[2] * alpha, alpha});
    }
}

void ui::node::impl::_set_needs_update_matrix() {
    _needs_update_matrix = true;
}
