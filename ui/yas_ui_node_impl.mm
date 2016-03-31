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

ui::node::impl::impl()
    : super_class(),
      _position(0.0f),
      _angle(0.0f),
      _local_matrix(matrix_identity_float4x4),
      _scale(1.0f),
      _needs_update_matrix(true),
      _enabled(true) {
}

ui::node::impl::~impl() {
}

simd::float2 ui::node::impl::position() {
    return _position;
}

Float32 ui::node::impl::angle() {
    return _angle;
}

simd::float2 ui::node::impl::scale() {
    return _scale;
}

simd::float4 ui::node::impl::color() {
    if (_mesh) {
        return _mesh.color();
    } else {
        return simd::float4{0.0f, 0.0f, 0.0f, 0.0f};
    }
}

ui::mesh ui::node::impl::mesh() {
    return _mesh;
}

bool ui::node::impl::is_enabled() {
    return _enabled;
}

void ui::node::impl::set_position(simd::float2 const pos) {
    _position = pos;
    _needs_update_matrix = true;
}

void ui::node::impl::set_angle(Float32 const angle) {
    _angle = angle;
    _needs_update_matrix = true;
}

void ui::node::impl::set_scale(simd::float2 const scale) {
    _scale = scale;
    _needs_update_matrix = true;
}

void ui::node::impl::set_color(simd::float4 const color) {
    if (_mesh) {
        _mesh.set_color(color);
    }
}

void ui::node::impl::set_mesh(ui::mesh &&mesh) {
    _mesh = std::move(mesh);
}

void ui::node::impl::set_enabled(bool const enabled) {
    _enabled = enabled;
}

void ui::node::impl::add_sub_node(ui::node &&sub_node) {
    auto sub_node_impl = sub_node.impl_ptr<impl>();

    children.emplace_back(std::move(sub_node));

    sub_node_impl->parent = cast<ui::node>();
    sub_node_impl->_node_renderer = _node_renderer;
}

void ui::node::impl::remove_sub_node(ui::node const &sub_node) {
    auto sub_node_impl = sub_node.impl_ptr<impl>();

    sub_node_impl->parent = nullptr;
    sub_node_impl->_node_renderer = nullptr;

    erase_if(children, [&sub_node](ui::node const &node) { return node == sub_node; });
}

void ui::node::impl::remove_from_super_node() {
    if (auto locked_parent = parent.lock()) {
        locked_parent.impl_ptr<impl>()->remove_sub_node(cast<ui::node>());
    }
}

void ui::node::impl::update_render_info(render_info &render_info) {
    if (!_enabled) {
        return;
    }

    update_matrix_for_render(render_info.render_matrix);
    update_touch_for_render(render_info.touch_matrix);

    if (_mesh) {
        _mesh.renderable().set_matrix(_render_matrix);
        if (auto encode_info = render_info.current_encode_info()) {
            encode_info.push_back_mesh(_mesh);
        }
    }

    for (auto &sub_node : children) {
        render_info.render_matrix = _render_matrix;
        render_info.touch_matrix = _touch_matrix;
        sub_node.impl_ptr<impl>()->update_render_info(render_info);
    }
}

ui::setup_metal_result ui::node::impl::setup(id<MTLDevice> const device) {
    if (_mesh) {
        if (auto ul = unless(_mesh.metal().setup(device))) {
            return std::move(ul.value);
        }
    }

    for (auto &sub_node : children) {
        if (auto ul = unless(sub_node.metal().setup(device))) {
            return std::move(ul.value);
        }
    }

    return ui::setup_metal_result{nullptr};
}

void ui::node::impl::update_matrix_for_render(simd::float4x4 const matrix) {
    if (_needs_update_matrix) {
        _local_matrix = matrix::translation(_position.x, _position.y) * matrix::rotation(_angle) *
                        matrix::scale(_scale.x, _scale.y);
        _needs_update_matrix = false;
    }

    _render_matrix = matrix * _local_matrix;
}

void ui::node::impl::update_touch_for_render(simd::float4x4 const matrix) {
    _touch_matrix = matrix * _local_matrix;
}

ui::node_renderer ui::node::impl::renderer() {
    return _node_renderer.lock();
}

void ui::node::impl::set_renderer(ui::node_renderer &&renderer) {
    _node_renderer = renderer;
}
