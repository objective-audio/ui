//
//  yas_ui_metal_system_protocol.mm
//

#include "yas_ui_metal_system_protocol.h"

using namespace yas;

#pragma mark - makable_metal_system

ui::makable_metal_system::makable_metal_system(std::shared_ptr<impl> impl) : protocol(std::move(impl)) {
}

ui::makable_metal_system::makable_metal_system(std::nullptr_t) : protocol(nullptr) {
}

objc_ptr<id<MTLTexture>> ui::makable_metal_system::make_mtl_texture(MTLTextureDescriptor *const textureDesc) {
    return impl_ptr<impl>()->make_mtl_texture(textureDesc);
}

objc_ptr<id<MTLSamplerState>> ui::makable_metal_system::make_mtl_sampler_state(
    MTLSamplerDescriptor *const samplerDesc) {
    return impl_ptr<impl>()->make_mtl_sampler_state(samplerDesc);
}

objc_ptr<id<MTLBuffer>> ui::makable_metal_system::make_mtl_buffer(std::size_t const length) {
    return impl_ptr<impl>()->make_mtl_buffer(length);
}

#pragma mark - renderable_metal_system

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

#pragma mark - testable_metal_system

ui::testable_metal_system::testable_metal_system(std::shared_ptr<impl> impl) : protocol(std::move(impl)) {
}

ui::testable_metal_system::testable_metal_system(std::nullptr_t) : protocol(nullptr) {
}

id<MTLDevice> ui::testable_metal_system::mtlDevice() {
    return impl_ptr<impl>()->mtlDevice();
}

uint32_t ui::testable_metal_system::sample_count() {
    return impl_ptr<impl>()->sample_count();
}

id<MTLRenderPipelineState> ui::testable_metal_system::mtlRenderPipelineStateWithTexture() {
    return impl_ptr<impl>()->mtlRenderPipelineStateWithTexture();
}

id<MTLRenderPipelineState> ui::testable_metal_system::mtlRenderPipelineStateWithoutTexture() {
    return impl_ptr<impl>()->mtlRenderPipelineStateWithoutTexture();
}
