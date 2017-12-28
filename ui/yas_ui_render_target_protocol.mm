//
//  yas_ui_render_target_protocol.mm
//

#include "yas_ui_render_target_protocol.h"

using namespace yas;

ui::renderable_render_target::renderable_render_target(std::shared_ptr<impl> impl) : protocol(std::move(impl)) {
}

ui::renderable_render_target::renderable_render_target(std::nullptr_t) : protocol(nullptr) {
}

ui::mesh &ui::renderable_render_target::mesh() {
    return impl_ptr<impl>()->mesh();
}

ui::effect &ui::renderable_render_target::effect() {
    return impl_ptr<impl>()->effect();
}

ui::render_target_updates_t const &ui::renderable_render_target::updates() {
    return impl_ptr<impl>()->updates();
}

void ui::renderable_render_target::clear_updates() {
    impl_ptr<impl>()->clear_updates();
}

MTLRenderPassDescriptor *ui::renderable_render_target::renderPassDescriptor() {
    return impl_ptr<impl>()->renderPassDescriptor();
}

simd::float4x4 const &ui::renderable_render_target::projection_matrix() {
    return impl_ptr<impl>()->projection_matrix();
}

void ui::renderable_render_target::push_encode_info(ui::render_stackable &stackable) {
    impl_ptr<impl>()->push_encode_info(stackable);
}
