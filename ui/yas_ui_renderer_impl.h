//
//  yas_ui_renderer_impl.h
//

#pragma once

@class YASUIGestureRecognizer;

#include <Metal/Metal.h>
#include "yas_ui_renderer_protocol.h"

class yas::ui::renderer::impl : public yas::base::impl, public yas::ui::view_renderable::impl {
   public:
    impl(id<MTLDevice> const device);

    id<MTLDevice> device();
    id<MTLBuffer> currentConstantBuffer();

    UInt32 constant_buffer_offset();
    void set_constant_buffer_offset(UInt32 const offset);

    id<MTLRenderPipelineState> multiSamplePipelineState();
    id<MTLRenderPipelineState> multiSamplePipelineStateWithoutTexture();
    simd::float4x4 const &projection_matrix();

    void view_configure(YASUIMetalView *const view) override;
    void view_drawable_size_will_change(YASUIMetalView *const view, CGSize const size) override;
    void view_render(YASUIMetalView *const view) override;

    virtual void render(id<MTLCommandBuffer> const commandBuffer, MTLRenderPassDescriptor *const renderPass_descriptor);

    yas::subject<ui::renderer> &subject();

   private:
    struct core;
    std::shared_ptr<core> _core;
};
