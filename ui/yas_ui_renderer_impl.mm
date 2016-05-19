//
//  yas_ui_renderer_impl.mm
//

#include <simd/simd.h>
#include "yas_each_index.h"
#include "yas_objc_ptr.h"
#include "yas_observing.h"
#include "yas_ui_event.h"
#include "yas_ui_matrix.h"
#include "yas_ui_metal_view.h"
#include "yas_ui_renderer.h"

using namespace yas;
using namespace simd;

@interface YASUIMetalView (yas_ui_renderer_impl)

- (void)set_event_manager:(ui::event_manager)manager;

@end

namespace yas {
namespace ui {
    static auto constexpr buffer_max_bytes = 1024 * 1024;
    static auto constexpr inflight_buffer_count = 2;
}
}

struct ui::renderer_base::impl::core {
    enum class update_result {
        no_change,
        changed,
    };

    uint32_t sample_count = 4;

    objc_ptr<id<MTLBuffer>> constant_buffers[inflight_buffer_count];
    uint8_t constant_buffer_index = 0;

    MTLPixelFormat depth_pixel_format = MTLPixelFormatInvalid;
    MTLPixelFormat stencil_pixel_format = MTLPixelFormatInvalid;

    objc_ptr<id<MTLDevice>> device;
    objc_ptr<id<MTLCommandQueue>> command_queue;
    objc_ptr<id<MTLLibrary>> default_library;

    objc_ptr<dispatch_semaphore_t> inflight_semaphore;

    uint32_t constant_buffer_offset = 0;
    ui::uint_size view_size;
    ui::uint_size drawable_size;
    double scale_factor = 0.0;
    simd::float4x4 projection_matrix;

    objc_ptr<id<MTLRenderPipelineState>> multi_sample_pipeline_state;
    objc_ptr<id<MTLRenderPipelineState>> multi_sample_pipeline_state_without_texture;
    objc_ptr<id<MTLRenderPipelineState>> pipeline_state;
    objc_ptr<id<MTLRenderPipelineState>> pipeline_state_without_texture;

    yas::subject<ui::renderer_base, ui::renderer_method> subject;

    ui::event_manager event_manager;

    update_result update_view_size(CGSize const v_size, CGSize const d_size) {
        auto const prev_view_size = view_size;
        auto const prev_drawable_size = drawable_size;

        float half_width = v_size.width * 0.5f;
        float half_height = v_size.height * 0.5f;

        view_size = {static_cast<uint32_t>(v_size.width), static_cast<uint32_t>(v_size.height)};
        drawable_size = {static_cast<uint32_t>(d_size.width), static_cast<uint32_t>(d_size.height)};

        if (view_size == prev_view_size && drawable_size == prev_drawable_size) {
            return update_result::no_change;
        } else {
            projection_matrix = ui::matrix::ortho(-half_width, half_width, -half_height, half_height, -1.0f, 1.0f);
            return update_result::changed;
        }
    }

    update_result update_scale_factor() {
        auto const prev_scale_factor = scale_factor;

        if (view_size.width > 0 && drawable_size.width > 0) {
            scale_factor = static_cast<double>(drawable_size.width) / static_cast<double>(view_size.width);
        } else if (view_size.height > 0 && drawable_size.height > 0) {
            scale_factor = static_cast<double>(drawable_size.height) / static_cast<double>(view_size.height);
        } else {
            scale_factor = 0.0;
        }

        if ((prev_scale_factor - 0.001) < scale_factor && scale_factor < (prev_scale_factor + 0.001)) {
            return update_result::no_change;
        } else {
            return update_result::changed;
        }
    }
};

#pragma mark - renderer::impl

ui::renderer_base::impl::impl(id<MTLDevice> const device) : _core(std::make_shared<core>()) {
    _core->device = device;
    _core->command_queue.move_object([device newCommandQueue]);
    _core->default_library.move_object([device newDefaultLibrary]);
    _core->inflight_semaphore.move_object(dispatch_semaphore_create(inflight_buffer_count));

    for (auto const &idx : make_each(inflight_buffer_count)) {
        _core->constant_buffers[idx].move_object([device newBufferWithLength:buffer_max_bytes options:kNilOptions]);
    }
}

void ui::renderer_base::impl::view_configure(YASUIMetalView *const view) {
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

    view_size_will_change(view, view.drawableSize);

    [view set_event_manager:_core->event_manager];
}

id<MTLDevice> ui::renderer_base::impl::device() {
    return _core->device.object();
}

id<MTLBuffer> ui::renderer_base::impl::currentConstantBuffer() {
    return _core->constant_buffers[_core->constant_buffer_index].object();
}

uint32_t ui::renderer_base::impl::constant_buffer_offset() {
    return _core->constant_buffer_offset;
}

void ui::renderer_base::impl::set_constant_buffer_offset(uint32_t const offset) {
    assert(offset < buffer_max_bytes);
    _core->constant_buffer_offset = offset;
}

id<MTLRenderPipelineState> ui::renderer_base::impl::multiSamplePipelineState() {
    return _core->multi_sample_pipeline_state.object();
}

id<MTLRenderPipelineState> ui::renderer_base::impl::multiSamplePipelineStateWithoutTexture() {
    return _core->multi_sample_pipeline_state_without_texture.object();
}

ui::uint_size const &ui::renderer_base::impl::view_size() {
    return _core->view_size;
}

ui::uint_size const &ui::renderer_base::impl::drawable_size() {
    return _core->drawable_size;
}

double ui::renderer_base::impl::scale_factor() {
    return _core->scale_factor;
}

simd::float4x4 const &ui::renderer_base::impl::projection_matrix() {
    return _core->projection_matrix;
}

#pragma mark - renderable::impl

void ui::renderer_base::impl::view_size_will_change(YASUIMetalView *const view, CGSize const drawable_size) {
    auto const view_size = view.bounds.size;
    auto const update_view_size_result = _core->update_view_size(view_size, drawable_size);
    auto const udpate_scale_result = _core->update_scale_factor();

    if (update_view_size_result == core::update_result::changed) {
        if (_core->subject.has_observer()) {
            _core->subject.notify(renderer_method::view_size_changed, cast<ui::renderer_base>());
        }

        if (udpate_scale_result == core::update_result::changed) {
            if (_core->subject.has_observer()) {
                _core->subject.notify(renderer_method::scale_factor_changed, cast<ui::renderer_base>());
            }
        }
    }
}

void ui::renderer_base::impl::view_render(YASUIMetalView *const view) {
    if (_core->subject.has_observer()) {
        _core->subject.notify(renderer_method::will_render, cast<ui::renderer_base>());
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

subject<ui::renderer_base, ui::renderer_method> &ui::renderer_base::impl::subject() {
    return _core->subject;
}

ui::event_manager &ui::renderer_base::impl::event_manager() {
    return _core->event_manager;
}

#pragma mark - virtual

void ui::renderer_base::impl::render(id<MTLCommandBuffer> const commandBuffer,
                                     MTLRenderPassDescriptor *const renderPassDesc) {
}
