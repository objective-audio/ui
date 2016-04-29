//
//  yas_ui_node.mm
//

#include "yas_ui_node.h"
#include "yas_ui_renderer.h"

using namespace yas;

#pragma mark - node

ui::node::node() : base(std::make_shared<impl>()) {
}

ui::node::node(std::shared_ptr<impl> &&impl) : base(std::move(impl)) {
}

ui::node::node(std::nullptr_t) : base(nullptr) {
}

bool ui::node::operator==(ui::node const &rhs) const {
    return base::operator==(rhs);
}

bool ui::node::operator!=(ui::node const &rhs) const {
    return base::operator!=(rhs);
}

simd::float2 ui::node::position() const {
    return impl_ptr<impl>()->position();
}

float ui::node::angle() const {
    return impl_ptr<impl>()->angle();
}

simd::float2 ui::node::scale() const {
    return impl_ptr<impl>()->scale();
}

simd::float3 ui::node::color() const {
    return impl_ptr<impl>()->color();
}

float ui::node::alpha() const {
    return impl_ptr<impl>()->alpha();
}

ui::mesh ui::node::mesh() const {
    return impl_ptr<impl>()->mesh();
}

ui::collider ui::node::collider() const {
    return impl_ptr<impl>()->collider();
}

bool ui::node::is_enabled() const {
    return impl_ptr<impl>()->is_enabled();
}

void ui::node::set_position(simd::float2 const pos) {
    impl_ptr<impl>()->set_position(pos);
}

void ui::node::set_angle(float const angle) {
    impl_ptr<impl>()->set_angle(angle);
}

void ui::node::set_scale(simd::float2 const scale) {
    impl_ptr<impl>()->set_scale(scale);
}

void ui::node::set_color(simd::float3 const color) {
    impl_ptr<impl>()->set_color(color);
}

void ui::node::set_alpha(float const alpha) {
    impl_ptr<impl>()->set_alpha(alpha);
}

void ui::node::set_mesh(ui::mesh mesh) {
    impl_ptr<impl>()->set_mesh(std::move(mesh));
}

void ui::node::set_collider(ui::collider collider) {
    impl_ptr<impl>()->set_collider(std::move(collider));
}

void ui::node::set_enabled(bool const enabled) {
    impl_ptr<impl>()->set_enabled(enabled);
}

void ui::node::add_sub_node(ui::node sub_node) {
    impl_ptr<impl>()->add_sub_node(std::move(sub_node));
}

void ui::node::remove_from_super_node() {
    impl_ptr<impl>()->remove_from_super_node();
}

std::vector<ui::node> const &ui::node::children() const {
    return impl_ptr<impl>()->children;
}

ui::node ui::node::parent() const {
    return impl_ptr<impl>()->parent.lock();
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

simd::float2 ui::node::convert_position(simd::float2 const &loc) {
    return impl_ptr<impl>()->convert_position(loc);
}
