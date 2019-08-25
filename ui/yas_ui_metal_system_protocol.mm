//
//  yas_ui_metal_system_protocol.mm
//

#include "yas_ui_metal_system_protocol.h"

using namespace yas;

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
