//
//  yas_ui_renderer_impl.h
//

#pragma once

#include <Metal/Metal.h>
#include "yas_ui_renderer_protocol.h"

namespace yas {
namespace ui {
    class event_manager;
}
}

class yas::ui::renderer_base::impl : public yas::base::impl, public yas::ui::view_renderable::impl {
   public:
    impl(id<MTLDevice> const device);

    id<MTLDevice> device();
    id<MTLBuffer> currentConstantBuffer();

    uint32_t constant_buffer_offset();
    void set_constant_buffer_offset(uint32_t const offset);

    id<MTLRenderPipelineState> multiSamplePipelineState();
    id<MTLRenderPipelineState> multiSamplePipelineStateWithoutTexture();

    ui::uint_size const &view_size();
    ui::uint_size const &drawable_size();
    double scale_factor();
    simd::float4x4 const &projection_matrix();

    void view_configure(YASUIMetalView *const view) override;
    void view_size_will_change(YASUIMetalView *const view, CGSize const size) override;
    void view_render(YASUIMetalView *const view) override;

    virtual void render(id<MTLCommandBuffer> const commandBuffer, MTLRenderPassDescriptor *const renderPass_descriptor);

    yas::subject<ui::renderer_base, ui::renderer_method> &subject();

    ui::event_manager &event_manager();

   private:
    struct core;
    std::shared_ptr<core> _core;
};
