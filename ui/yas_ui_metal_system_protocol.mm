//
//  yas_ui_metal_system_protocol.mm
//

#include "yas_ui_metal_system_protocol.h"

using namespace yas;

ui::renderable_metal_system::renderable_metal_system(std::shared_ptr<impl> impl) : protocol(std::move(impl)) {
}

ui::renderable_metal_system::renderable_metal_system(std::nullptr_t) : protocol(nullptr) {
}

void ui::renderable_metal_system::view_configure(yas_objc_view *const view) {
    impl_ptr<impl>()->view_configure(view);
}

void ui::renderable_metal_system::view_render(yas_objc_view *const view, ui::renderer &renderer) {
    impl_ptr<impl>()->view_render(view, renderer);
}

void ui::renderable_metal_system::prepare_uniforms_buffer(uint32_t const uniforms_count) {
    impl_ptr<impl>()->prepare_uniforms_buffer(uniforms_count);
}

void ui::renderable_metal_system::mesh_encode(ui::mesh &mesh, id<MTLRenderCommandEncoder> const encoder,
                                              ui::metal_encode_info const &encode_info) {
    impl_ptr<impl>()->mesh_encode(mesh, encoder, encode_info);
}
