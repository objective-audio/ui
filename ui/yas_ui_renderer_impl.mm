//
//  yas_ui_renderer_impl.mm
//

#include <simd/simd.h>
#include "yas_each_index.h"
#include "yas_objc_ptr.h"
#include "yas_observing.h"
#include "yas_ui_event.h"
#include "yas_ui_math.h"
#include "yas_ui_matrix.h"
#include "yas_ui_metal_view.h"
#include "yas_ui_renderer.h"

using namespace yas;

@interface YASUIMetalView (yas_ui_renderer_impl)

- (void)set_event_manager:(ui::event_manager)manager;

@end

namespace yas {
namespace ui {
    static auto constexpr _buffer_max_bytes = 1024 * 1024;
    static auto constexpr _inflight_buffer_count = 2;
}
}

struct ui::renderer_base::impl::core {
    enum class update_result {
        no_change,
        changed,
    };

    uint32_t _sample_count = 4;

    objc_ptr<id<MTLBuffer>> _constant_buffers[_inflight_buffer_count];
    uint8_t _constant_buffer_index = 0;

    MTLPixelFormat _depth_pixel_format = MTLPixelFormatInvalid;
    MTLPixelFormat _stencil_pixel_format = MTLPixelFormatInvalid;

    objc_ptr<id<MTLDevice>> _device;
    objc_ptr<id<MTLCommandQueue>> _command_queue;
    objc_ptr<id<MTLLibrary>> _default_library;

    objc_ptr<dispatch_semaphore_t> _inflight_semaphore;

    uint32_t _constant_buffer_offset = 0;
    ui::uint_size _view_size = {0, 0};
    ui::uint_size _drawable_size = {0, 0};
    double _scale_factor = 0.0;
    simd::float4x4 _projection_matrix;

    objc_ptr<id<MTLRenderPipelineState>> _multi_sample_pipeline_state;
    objc_ptr<id<MTLRenderPipelineState>> _multi_sample_pipeline_state_without_texture;
    objc_ptr<id<MTLRenderPipelineState>> _pipeline_state;
    objc_ptr<id<MTLRenderPipelineState>> _pipeline_state_without_texture;

    yas::subject<ui::renderer_base, ui::renderer_method> _subject;

    ui::event_manager _event_manager;

    update_result update_view_size(CGSize const v_size, CGSize const d_size) {
        auto const prev_view_size = _view_size;
        auto const prev_drawable_size = _drawable_size;

        float half_width = v_size.width * 0.5f;
        float half_height = v_size.height * 0.5f;

        _view_size = {static_cast<uint32_t>(v_size.width), static_cast<uint32_t>(v_size.height)};
        _drawable_size = {static_cast<uint32_t>(d_size.width), static_cast<uint32_t>(d_size.height)};

        if (_view_size == prev_view_size && _drawable_size == prev_drawable_size) {
            return update_result::no_change;
        } else {
            _projection_matrix = ui::matrix::ortho(-half_width, half_width, -half_height, half_height, -1.0f, 1.0f);
            return update_result::changed;
        }
    }

    update_result update_scale_factor() {
        auto const prev_scale_factor = _scale_factor;

        if (_view_size.width > 0 && _drawable_size.width > 0) {
            _scale_factor = static_cast<double>(_drawable_size.width) / static_cast<double>(_view_size.width);
        } else if (_view_size.height > 0 && _drawable_size.height > 0) {
            _scale_factor = static_cast<double>(_drawable_size.height) / static_cast<double>(_view_size.height);
        } else {
            _scale_factor = 0.0;
        }

        if (std::abs(_scale_factor - prev_scale_factor) < std::numeric_limits<double>::epsilon()) {
            return update_result::no_change;
        } else {
            return update_result::changed;
        }
    }
};

#pragma mark - renderer::impl

ui::renderer_base::impl::impl(id<MTLDevice> const device) : _core(std::make_shared<core>()) {
    _core->_device = device;
    _core->_command_queue.move_object([device newCommandQueue]);
    _core->_default_library.move_object([device newDefaultLibrary]);
    _core->_inflight_semaphore.move_object(dispatch_semaphore_create(_inflight_buffer_count));

    for (auto const &idx : make_each(_inflight_buffer_count)) {
        _core->_constant_buffers[idx].move_object([device newBufferWithLength:_buffer_max_bytes options:kNilOptions]);
    }
}

void ui::renderer_base::impl::view_configure(YASUIMetalView *const view) {
    view.sampleCount = _core->_sample_count;

    auto defaultLibrary = _core->_default_library.object();
    auto device = _core->_device.object();

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
    pipelineStateDesc.sampleCount = _core->_sample_count;
    pipelineStateDesc.vertexFunction = vertexProgram;
    pipelineStateDesc.fragmentFunction = fragmentProgram;
    [pipelineStateDesc.colorAttachments setObject:colorDesc atIndexedSubscript:0];
    pipelineStateDesc.depthAttachmentPixelFormat = _core->_depth_pixel_format;
    pipelineStateDesc.stencilAttachmentPixelFormat = _core->_stencil_pixel_format;

    _core->_multi_sample_pipeline_state.move_object(
        [device newRenderPipelineStateWithDescriptor:pipelineStateDesc error:nil]);

    pipelineStateDesc.fragmentFunction = fragmentProgramWithoutTexture;

    _core->_multi_sample_pipeline_state_without_texture.move_object(
        [device newRenderPipelineStateWithDescriptor:pipelineStateDesc error:nil]);

    pipelineStateDesc.sampleCount = 1;

    _core->_pipeline_state_without_texture.move_object(
        [device newRenderPipelineStateWithDescriptor:pipelineStateDesc error:nil]);

    pipelineStateDesc.fragmentFunction = fragmentProgram;

    _core->_pipeline_state.move_object([device newRenderPipelineStateWithDescriptor:pipelineStateDesc error:nil]);

#if TARGET_OS_IPHONE
    auto const view_size = view.frame.size;
    auto const scale = view.contentScaleFactor;
    auto const drawable_size = CGSizeMake(std::round(view_size.width * scale), std::round(view_size.height * scale));
#elif TARGET_OS_MAC
    auto const drawable_size = view.drawableSize;
#endif

    view_size_will_change(view, drawable_size);

    [view set_event_manager:_core->_event_manager];
}

id<MTLDevice> ui::renderer_base::impl::device() {
    return _core->_device.object();
}

id<MTLBuffer> ui::renderer_base::impl::currentConstantBuffer() {
    return _core->_constant_buffers[_core->_constant_buffer_index].object();
}

uint32_t ui::renderer_base::impl::constant_buffer_offset() {
    return _core->_constant_buffer_offset;
}

void ui::renderer_base::impl::set_constant_buffer_offset(uint32_t const offset) {
    assert(offset < _buffer_max_bytes);
    _core->_constant_buffer_offset = offset;
}

id<MTLRenderPipelineState> ui::renderer_base::impl::multiSamplePipelineState() {
    return _core->_multi_sample_pipeline_state.object();
}

id<MTLRenderPipelineState> ui::renderer_base::impl::multiSamplePipelineStateWithoutTexture() {
    return _core->_multi_sample_pipeline_state_without_texture.object();
}

ui::uint_size const &ui::renderer_base::impl::view_size() {
    return _core->_view_size;
}

ui::uint_size const &ui::renderer_base::impl::drawable_size() {
    return _core->_drawable_size;
}

double ui::renderer_base::impl::scale_factor() {
    return _core->_scale_factor;
}

simd::float4x4 const &ui::renderer_base::impl::projection_matrix() {
    return _core->_projection_matrix;
}

#pragma mark - renderable::impl

void ui::renderer_base::impl::view_size_will_change(YASUIMetalView *const view, CGSize const drawable_size) {
    auto const view_size = view.bounds.size;
    auto const update_view_size_result = _core->update_view_size(view_size, drawable_size);
    auto const update_scale_result = _core->update_scale_factor();

    if (update_view_size_result == core::update_result::changed) {
        if (_core->_subject.has_observer()) {
            _core->_subject.notify(renderer_method::view_size_changed, cast<ui::renderer_base>());
        }

        if (update_scale_result == core::update_result::changed) {
            if (_core->_subject.has_observer()) {
                _core->_subject.notify(renderer_method::scale_factor_changed, cast<ui::renderer_base>());
            }
        }
    }
}

void ui::renderer_base::impl::view_render(YASUIMetalView *const view) {
    if (_core->_subject.has_observer()) {
        _core->_subject.notify(renderer_method::will_render, cast<ui::renderer_base>());
    }

    if (!pre_render()) {
        return;
    }

    dispatch_semaphore_wait(_core->_inflight_semaphore.object(), DISPATCH_TIME_FOREVER);

    auto command_buffer = make_objc_ptr<id<MTLCommandBuffer>>([commandQueue = _core->_command_queue.object()]() {
        return [commandQueue commandBuffer];
    });
    auto commandBuffer = command_buffer.object();

    _core->_constant_buffer_offset = 0;

    auto renderPassDesc = view.currentRenderPassDescriptor;
    assert(renderPassDesc);

    render(commandBuffer, renderPassDesc);

    [commandBuffer addCompletedHandler:[semaphore = _core->_inflight_semaphore](id<MTLCommandBuffer> _Nonnull) {
        dispatch_semaphore_signal(semaphore.object());
    }];

    _core->_constant_buffer_index = (_core->_constant_buffer_index + 1) % _inflight_buffer_count;

    [commandBuffer presentDrawable:view.currentDrawable];
    [commandBuffer commit];
}

subject<ui::renderer_base, ui::renderer_method> &ui::renderer_base::impl::subject() {
    return _core->_subject;
}

ui::event_manager &ui::renderer_base::impl::event_manager() {
    return _core->_event_manager;
}

#pragma mark - virtual

bool ui::renderer_base::impl::pre_render() {
    return false;
}

void ui::renderer_base::impl::render(id<MTLCommandBuffer> const commandBuffer,
                                     MTLRenderPassDescriptor *const renderPassDesc) {
}
