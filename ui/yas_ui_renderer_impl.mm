//
//  yas_ui_renderer_impl.mm
//

#include <simd/simd.h>
#include "yas_each_index.h"
#include "yas_objc_ptr.h"
#include "yas_observing.h"
#include "yas_ui_matrix.h"
#include "yas_ui_renderer.h"

using namespace yas;
using namespace simd;

namespace yas {
namespace ui {
    static auto constexpr buffer_max_bytes = 1024 * 1024;
    static auto constexpr inflight_buffer_count = 2;
}
}

struct ui::renderer::impl::core {
    UInt32 sample_count = 4;

    objc_ptr<id<MTLBuffer>> constant_buffers[inflight_buffer_count];
    UInt8 constant_buffer_index = 0;

    MTLPixelFormat depth_pixel_format = MTLPixelFormatInvalid;
    MTLPixelFormat stencil_pixel_format = MTLPixelFormatInvalid;

    objc_ptr<id<MTLDevice>> device;
    objc_ptr<id<MTLCommandQueue>> command_queue;
    objc_ptr<id<MTLLibrary>> default_library;

    objc_ptr<dispatch_semaphore_t> inflight_semaphore;

    UInt32 constant_buffer_offset = 0;
    simd::float4x4 projection_matrix;

    objc_ptr<id<MTLRenderPipelineState>> multi_sample_pipeline_state;
    objc_ptr<id<MTLRenderPipelineState>> multi_sample_pipeline_state_without_texture;
    objc_ptr<id<MTLRenderPipelineState>> pipeline_state;
    objc_ptr<id<MTLRenderPipelineState>> pipeline_state_without_texture;

    yas::subject<renderer> subject;

    void update_projection_matrix(CGSize const view_size) {
        float half_width = view_size.width * 0.5f;
        float half_height = view_size.height * 0.5f;

        projection_matrix = ui::matrix::ortho(-half_width, half_width, -half_height, half_height, -1.0f, 1.0f);
    }
};

#pragma mark - renderer::impl

ui::renderer::impl::impl(id<MTLDevice> const device) : _core(std::make_shared<core>()) {
    _core->device = device;
    _core->command_queue.move_object([device newCommandQueue]);
    _core->default_library.move_object([device newDefaultLibrary]);
    _core->inflight_semaphore.move_object(dispatch_semaphore_create(inflight_buffer_count));

    for (auto const &idx : make_each(inflight_buffer_count)) {
        _core->constant_buffers[idx].move_object([device newBufferWithLength:buffer_max_bytes options:kNilOptions]);
    }
}

void ui::renderer::impl::view_configure(MTKView *const view) {
    view.sampleCount = _core->sample_count;

    auto defaultLibrary = _core->default_library.object();
    auto device = _core->device.object();

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
    pipelineStateDesc.sampleCount = _core->sample_count;
    pipelineStateDesc.vertexFunction = vertexProgram;
    pipelineStateDesc.fragmentFunction = fragmentProgram;
    [pipelineStateDesc.colorAttachments setObject:colorDesc atIndexedSubscript:0];
    pipelineStateDesc.depthAttachmentPixelFormat = _core->depth_pixel_format;
    pipelineStateDesc.stencilAttachmentPixelFormat = _core->stencil_pixel_format;

    _core->multi_sample_pipeline_state.move_object(
        [device newRenderPipelineStateWithDescriptor:pipelineStateDesc error:nil]);

    pipelineStateDesc.fragmentFunction = fragmentProgramWithoutTexture;

    _core->multi_sample_pipeline_state_without_texture.move_object(
        [device newRenderPipelineStateWithDescriptor:pipelineStateDesc error:nil]);

    pipelineStateDesc.sampleCount = 1;

    _core->pipeline_state_without_texture.move_object(
        [device newRenderPipelineStateWithDescriptor:pipelineStateDesc error:nil]);

    pipelineStateDesc.fragmentFunction = fragmentProgram;

    _core->pipeline_state.move_object([device newRenderPipelineStateWithDescriptor:pipelineStateDesc error:nil]);

    _core->update_projection_matrix(view.bounds.size);
}

id<MTLDevice> ui::renderer::impl::device() {
    return _core->device.object();
}

id<MTLBuffer> ui::renderer::impl::currentConstantBuffer() {
    return _core->constant_buffers[_core->constant_buffer_index].object();
}

UInt32 ui::renderer::impl::constant_buffer_offset() {
    return _core->constant_buffer_offset;
}

void ui::renderer::impl::set_constant_buffer_offset(UInt32 const offset) {
    assert(offset < buffer_max_bytes);
    _core->constant_buffer_offset = offset;
}

id<MTLRenderPipelineState> ui::renderer::impl::multiSamplePipelineState() {
    return _core->multi_sample_pipeline_state.object();
}

id<MTLRenderPipelineState> ui::renderer::impl::multiSamplePipelineStateWithoutTexture() {
    return _core->multi_sample_pipeline_state_without_texture.object();
}

simd::float4x4 const &ui::renderer::impl::projection_matrix() {
    return _core->projection_matrix;
}

#pragma mark - renderable::impl

void ui::renderer::impl::view_drawable_size_will_change(MTKView *const view, CGSize const size) {
    auto view_size = view.bounds.size;
    _core->update_projection_matrix(view_size);
}

void ui::renderer::impl::view_render(MTKView *const view) {
    if (_core->subject.has_observer()) {
        _core->subject.notify(renderer_method::will_render, cast<renderer>());
    }

    dispatch_semaphore_wait(_core->inflight_semaphore.object(), DISPATCH_TIME_FOREVER);

    auto command_buffer = make_objc_ptr<id<MTLCommandBuffer>>([commandQueue = _core->command_queue.object()]() {
        return [commandQueue commandBuffer];
    });
    auto commandBuffer = command_buffer.object();

    _core->constant_buffer_offset = 0;

    auto renderPassDesc = view.currentRenderPassDescriptor;
    assert(renderPassDesc);

    render(commandBuffer, renderPassDesc);

    [commandBuffer addCompletedHandler:[semaphore = _core->inflight_semaphore](id<MTLCommandBuffer> _Nonnull) {
        dispatch_semaphore_signal(semaphore.object());
    }];

    _core->constant_buffer_index = (_core->constant_buffer_index + 1) % inflight_buffer_count;

    [commandBuffer presentDrawable:view.currentDrawable];
    [commandBuffer commit];
}

subject<ui::renderer> &ui::renderer::impl::subject() {
    return _core->subject;
}

#pragma mark - virtual

void ui::renderer::impl::render(id<MTLCommandBuffer> const commandBuffer,
                                MTLRenderPassDescriptor *const renderPassDesc) {
}
