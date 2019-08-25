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

objc_ptr<id<MTLArgumentEncoder>> ui::makable_metal_system::make_mtl_argument_encoder() {
    return impl_ptr<impl>()->make_mtl_argument_encoder();
}

objc_ptr<id<MTLBuffer>> ui::makable_metal_system::make_mtl_buffer(std::size_t const length) {
    return impl_ptr<impl>()->make_mtl_buffer(length);
}

objc_ptr<MPSImageGaussianBlur *> ui::makable_metal_system::make_mtl_blur(double const sigma) {
    return impl_ptr<impl>()->make_mtl_blur(sigma);
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
