//
//  yas_ui_metal_system.mm
//

#include "yas_each_index.h"
#include "yas_objc_ptr.h"
#include "yas_ui_metal_encode_info.h"
#include "yas_ui_metal_render_encoder.h"
#include "yas_ui_metal_system.h"
#include "yas_ui_metal_view.h"
#include "yas_ui_node.h"
#include "yas_ui_render_info.h"
#include "yas_ui_renderer.h"

using namespace yas;

namespace yas {
namespace ui {
    static auto constexpr _buffer_max_bytes = 1024 * 1024;
    static auto constexpr _inflight_buffer_count = 2;
}
}

#pragma mark - ui::metal_system::impl

struct ui::metal_system::impl : base::impl {
    impl(id<MTLDevice> const device) : _device(device) {
        _command_queue.move_object([device newCommandQueue]);
        _default_library.move_object([device newDefaultLibrary]);
        _inflight_semaphore.move_object(dispatch_semaphore_create(_inflight_buffer_count));

        for (auto const &idx : make_each(_inflight_buffer_count)) {
            _constant_buffers[idx].move_object([device newBufferWithLength:_buffer_max_bytes options:kNilOptions]);
        }

        auto defaultLibrary = _default_library.object();

        auto fragment_program = make_objc_ptr([defaultLibrary newFunctionWithName:@"fragment2d"]);
        auto fragment_program_without_texture =
            make_objc_ptr([defaultLibrary newFunctionWithName:@"fragment2d_without_texture"]);
        auto vertex_program = make_objc_ptr([defaultLibrary newFunctionWithName:@"vertex2d"]);

        auto fragmentProgram = fragment_program.object();
        auto fragmentProgramWithoutTexture = fragment_program_without_texture.object();
        auto vertexProgram = vertex_program.object();

        assert(fragmentProgram);
        assert(fragmentProgramWithoutTexture);
        assert(vertexProgram);

        auto color_desc = make_objc_ptr([MTLRenderPipelineColorAttachmentDescriptor new]);
        auto colorDesc = color_desc.object();
        colorDesc.pixelFormat = MTLPixelFormatBGRA8Unorm;
        colorDesc.blendingEnabled = YES;
        colorDesc.rgbBlendOperation = MTLBlendOperationAdd;
        colorDesc.alphaBlendOperation = MTLBlendOperationAdd;
        colorDesc.sourceRGBBlendFactor = MTLBlendFactorOne;
        colorDesc.sourceAlphaBlendFactor = MTLBlendFactorOne;
        colorDesc.destinationRGBBlendFactor = MTLBlendFactorOneMinusSourceAlpha;
        colorDesc.destinationAlphaBlendFactor = MTLBlendFactorOneMinusSourceAlpha;

        auto pipeline_state_desc = make_objc_ptr([MTLRenderPipelineDescriptor new]);
        auto pipelineStateDesc = pipeline_state_desc.object();
        pipelineStateDesc.sampleCount = _sample_count;
        pipelineStateDesc.vertexFunction = vertexProgram;
        pipelineStateDesc.fragmentFunction = fragmentProgram;
        [pipelineStateDesc.colorAttachments setObject:colorDesc atIndexedSubscript:0];
        pipelineStateDesc.depthAttachmentPixelFormat = _depth_pixel_format;
        pipelineStateDesc.stencilAttachmentPixelFormat = _stencil_pixel_format;

        _multi_sample_pipeline_state.move_object(
            [device newRenderPipelineStateWithDescriptor:pipelineStateDesc error:nil]);

        pipelineStateDesc.fragmentFunction = fragmentProgramWithoutTexture;

        _multi_sample_pipeline_state_without_texture.move_object(
            [device newRenderPipelineStateWithDescriptor:pipelineStateDesc error:nil]);

        pipelineStateDesc.sampleCount = 1;

        _pipeline_state_without_texture.move_object(
            [device newRenderPipelineStateWithDescriptor:pipelineStateDesc error:nil]);

        pipelineStateDesc.fragmentFunction = fragmentProgram;

        _pipeline_state.move_object([device newRenderPipelineStateWithDescriptor:pipelineStateDesc error:nil]);
    }

    void view_render(YASUIMetalView *const view, ui::renderer &renderer) {
        dispatch_semaphore_wait(_inflight_semaphore.object(), DISPATCH_TIME_FOREVER);

        auto command_buffer = make_objc_ptr<id<MTLCommandBuffer>>([commandQueue = _command_queue.object()]() {
            return [commandQueue commandBuffer];
        });
        auto commandBuffer = command_buffer.object();

        _constant_buffer_offset = 0;

        auto renderPassDesc = view.currentRenderPassDescriptor;
        assert(renderPassDesc);

        render(renderer, commandBuffer, renderPassDesc);

        [commandBuffer addCompletedHandler:[semaphore = _inflight_semaphore](id<MTLCommandBuffer> _Nonnull) {
            dispatch_semaphore_signal(semaphore.object());
        }];

        _constant_buffer_index = (_constant_buffer_index + 1) % _inflight_buffer_count;

        [commandBuffer presentDrawable:view.currentDrawable];
        [commandBuffer commit];
    }

    void render(ui::renderer &renderer, id<MTLCommandBuffer> const commandBuffer,
                MTLRenderPassDescriptor *const renderPassDesc) {
        ui::metal_render_encoder metal_render_encoder;
        metal_render_encoder.push_encode_info({renderPassDesc, _multi_sample_pipeline_state.object(),
                                               _multi_sample_pipeline_state_without_texture.object()});

        ui::render_info render_info{.collision_detector = renderer.collision_detector(),
                                    .render_encodable = metal_render_encoder.encodable(),
                                    .matrix = renderer.projection_matrix(),
                                    .mesh_matrix = renderer.projection_matrix()};

        auto metal_system = cast<ui::metal_system>();

        renderer.root_node().metal().metal_setup(metal_system);
        renderer.root_node().renderable().build_render_info(render_info);

        for (auto &batch : render_info.batches) {
            batch.metal().metal_setup(metal_system);
        }

        metal_render_encoder.render(renderer, commandBuffer, renderPassDesc);
    }

    uint32_t _sample_count = 4;

    objc_ptr<id<MTLBuffer>> _constant_buffers[_inflight_buffer_count];
    uint8_t _constant_buffer_index = 0;
    uint32_t _constant_buffer_offset = 0;

    MTLPixelFormat _depth_pixel_format = MTLPixelFormatInvalid;
    MTLPixelFormat _stencil_pixel_format = MTLPixelFormatInvalid;

    objc_ptr<id<MTLDevice>> _device;
    objc_ptr<id<MTLCommandQueue>> _command_queue;
    objc_ptr<id<MTLLibrary>> _default_library;

    objc_ptr<dispatch_semaphore_t> _inflight_semaphore;

    objc_ptr<id<MTLRenderPipelineState>> _multi_sample_pipeline_state;
    objc_ptr<id<MTLRenderPipelineState>> _multi_sample_pipeline_state_without_texture;
    objc_ptr<id<MTLRenderPipelineState>> _pipeline_state;
    objc_ptr<id<MTLRenderPipelineState>> _pipeline_state_without_texture;
};

#pragma mark - ui::metal_system

ui::metal_system::metal_system(id<MTLDevice> const device) : base(std::make_shared<impl>(device)) {
}

ui::metal_system::metal_system(std::nullptr_t) : base(nullptr) {
}

id<MTLDevice> ui::metal_system::device() const {
    return impl_ptr<impl>()->_device.object();
}

id<MTLBuffer> ui::metal_system::currentConstantBuffer() const {
    return impl_ptr<impl>()->_constant_buffers[impl_ptr<impl>()->_constant_buffer_index].object();
}

uint32_t ui::metal_system::constant_buffer_offset() const {
    return impl_ptr<impl>()->_constant_buffer_offset;
}

void ui::metal_system::set_constant_buffer_offset(uint32_t const offset) {
    assert(offset < _buffer_max_bytes);
    impl_ptr<impl>()->_constant_buffer_offset = offset;
}

uint32_t ui::metal_system::sample_count() const {
    return impl_ptr<impl>()->_sample_count;
}

void ui::metal_system::view_render(yas_objc_view *const view, ui::renderer &renderer) {
    if ([view isKindOfClass:[YASUIMetalView class]]) {
        impl_ptr<impl>()->view_render((YASUIMetalView * const)view, renderer);
    }
}
