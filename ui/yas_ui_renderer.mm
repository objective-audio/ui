//
//  yas_ui_renderer.mm
//

#include <simd/simd.h>
#include <chrono>
#include "yas_each_index.h"
#include "yas_objc_ptr.h"
#include "yas_observing.h"
#include "yas_to_bool.h"
#include "yas_ui_action.h"
#include "yas_ui_collision_detector.h"
#include "yas_ui_event.h"
#include "yas_ui_math.h"
#include "yas_ui_matrix.h"
#include "yas_ui_mesh.h"
#include "yas_ui_metal_encode_info.h"
#include "yas_ui_metal_render_encoder.h"
#include "yas_ui_metal_view.h"
#include "yas_ui_node.h"
#include "yas_ui_render_info.h"
#include "yas_ui_renderer.h"
#include "yas_ui_types.h"

using namespace yas;

@interface YASUIMetalView (yas_ui_renderer)

- (void)set_event_manager:(ui::event_manager)manager;

@end

namespace yas {
namespace ui {
    static auto constexpr _buffer_max_bytes = 1024 * 1024;
    static auto constexpr _inflight_buffer_count = 2;
}
}

struct yas::ui::renderer::impl : yas::base::impl, yas::ui::view_renderable::impl {
    enum class update_result {
        no_change,
        changed,
    };

    impl(id<MTLDevice> const device)
        : _device(device),
          _command_queue(make_objc_ptr([device newCommandQueue])),
          _default_library(make_objc_ptr([device newDefaultLibrary])),
          _inflight_semaphore(make_objc_ptr(dispatch_semaphore_create(_inflight_buffer_count))) {
        for (auto const &idx : make_each(_inflight_buffer_count)) {
            _constant_buffers[idx].move_object([device newBufferWithLength:_buffer_max_bytes options:kNilOptions]);
        }
    }

    void view_configure(YASUIMetalView *const view) {
        view.sampleCount = _sample_count;

        auto defaultLibrary = _default_library.object();
        auto device = _device.object();

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

#if TARGET_OS_IPHONE
        auto const view_size = view.frame.size;
        auto const scale = view.contentScaleFactor;
        auto const drawable_size =
            CGSizeMake(std::round(view_size.width * scale), std::round(view_size.height * scale));
#elif TARGET_OS_MAC
        auto const drawable_size = view.drawableSize;
#endif

        view_size_will_change(view, drawable_size);

        [view set_event_manager:_event_manager];
    }

    id<MTLDevice> device() {
        return _device.object();
    }

    id<MTLBuffer> currentConstantBuffer() {
        return _constant_buffers[_constant_buffer_index].object();
    }

    uint32_t constant_buffer_offset() {
        return _constant_buffer_offset;
    }

    void set_constant_buffer_offset(uint32_t const offset) {
        assert(offset < _buffer_max_bytes);
        _constant_buffer_offset = offset;
    }

    id<MTLRenderPipelineState> multiSamplePipelineState() {
        return _multi_sample_pipeline_state.object();
    }

    id<MTLRenderPipelineState> multiSamplePipelineStateWithoutTexture() {
        return _multi_sample_pipeline_state_without_texture.object();
    }

    void view_size_will_change(YASUIMetalView *const view, CGSize const drawable_size) {
        auto const view_size = view.bounds.size;
        auto const update_view_size_result = _update_view_size(view_size, drawable_size);
        auto const update_scale_result = _update_scale_factor();

        if (to_bool(update_view_size_result)) {
            if (_subject.has_observer()) {
                _subject.notify(renderer_method::view_size_changed, cast<ui::renderer>());
            }

            if (to_bool(update_scale_result)) {
                if (_subject.has_observer()) {
                    _subject.notify(renderer_method::scale_factor_changed, cast<ui::renderer>());
                }
            }
        }
    }

    void view_render(YASUIMetalView *const view) {
        if (_subject.has_observer()) {
            _subject.notify(renderer_method::will_render, cast<ui::renderer>());
        }

        if (pre_render()) {
            dispatch_semaphore_wait(_inflight_semaphore.object(), DISPATCH_TIME_FOREVER);

            auto command_buffer = make_objc_ptr<id<MTLCommandBuffer>>([commandQueue = _command_queue.object()]() {
                return [commandQueue commandBuffer];
            });
            auto commandBuffer = command_buffer.object();

            _constant_buffer_offset = 0;

            auto renderPassDesc = view.currentRenderPassDescriptor;
            assert(renderPassDesc);

            render(commandBuffer, renderPassDesc);

            [commandBuffer addCompletedHandler:[semaphore = _inflight_semaphore](id<MTLCommandBuffer> _Nonnull) {
                dispatch_semaphore_signal(semaphore.object());
            }];

            _constant_buffer_index = (_constant_buffer_index + 1) % _inflight_buffer_count;

            [commandBuffer presentDrawable:view.currentDrawable];
            [commandBuffer commit];
        }

        post_render();
    }

    void insert_action(ui::action action) {
        _action.insert_action(action);
    }

    void erase_action(ui::action const &action) {
        _action.erase_action(action);
    }

    void erase_action(ui::node const &target) {
        for (auto const &action : _action.actions()) {
            if (action.target() == target) {
                _action.erase_action(action);
            }
        }
    }

    bool pre_render() {
        _action.updatable().update(std::chrono::system_clock::now());

        ui::tree_updates tree_updates;
        _root_node.renderable().fetch_updates(tree_updates);

        if (tree_updates.is_collider_updated()) {
            _detector.updatable().begin_update();
        }

        return tree_updates.is_any_updated();
    }

    void render(id<MTLCommandBuffer> const commandBuffer, MTLRenderPassDescriptor *const renderPassDesc) {
        ui::metal_render_encoder metal_render_encoder;
        metal_render_encoder.push_encode_info(
            {renderPassDesc, multiSamplePipelineState(), multiSamplePipelineStateWithoutTexture()});

        ui::render_info render_info{.collision_detector = _detector,
                                    .render_encodable = metal_render_encoder.encodable(),
                                    .matrix = _projection_matrix,
                                    .mesh_matrix = _projection_matrix};

        _root_node.metal().metal_setup(device());
        _root_node.renderable().build_render_info(render_info);

        for (auto &batch : render_info.batches) {
            batch.metal().metal_setup(device());
        }

        auto renderer = cast<ui::renderer>();
        metal_render_encoder.render(renderer, commandBuffer, renderPassDesc);
    }

    void post_render() {
        _root_node.renderable().clear_updates();
        _detector.updatable().end_update();
    }

    objc_ptr<id<MTLDevice>> _device;

    uint32_t _sample_count = 4;
    ui::uint_size _view_size = {.width = 0, .height = 0};
    ui::uint_size _drawable_size = {.width = 0, .height = 0};
    double _scale_factor = 0.0;
    simd::float4x4 _projection_matrix = matrix_identity_float4x4;

    yas::subject<ui::renderer, ui::renderer_method> _subject;

    ui::node _root_node;
    ui::parallel_action _action;
    ui::collision_detector _detector;
    ui::event_manager _event_manager;

   private:
    objc_ptr<id<MTLBuffer>> _constant_buffers[_inflight_buffer_count];
    uint8_t _constant_buffer_index = 0;
    uint32_t _constant_buffer_offset = 0;

    MTLPixelFormat _depth_pixel_format = MTLPixelFormatInvalid;
    MTLPixelFormat _stencil_pixel_format = MTLPixelFormatInvalid;

    objc_ptr<id<MTLCommandQueue>> _command_queue;
    objc_ptr<id<MTLLibrary>> _default_library;
    objc_ptr<dispatch_semaphore_t> _inflight_semaphore;

    objc_ptr<id<MTLRenderPipelineState>> _multi_sample_pipeline_state;
    objc_ptr<id<MTLRenderPipelineState>> _multi_sample_pipeline_state_without_texture;
    objc_ptr<id<MTLRenderPipelineState>> _pipeline_state;
    objc_ptr<id<MTLRenderPipelineState>> _pipeline_state_without_texture;

    update_result _update_view_size(CGSize const v_size, CGSize const d_size) {
        auto const prev_view_size = _view_size;
        auto const prev_drawable_size = _drawable_size;

        float const half_width = v_size.width * 0.5f;
        float const half_height = v_size.height * 0.5f;

        _view_size = {static_cast<uint32_t>(v_size.width), static_cast<uint32_t>(v_size.height)};
        _drawable_size = {static_cast<uint32_t>(d_size.width), static_cast<uint32_t>(d_size.height)};

        if (_view_size == prev_view_size && _drawable_size == prev_drawable_size) {
            return update_result::no_change;
        } else {
            _projection_matrix = ui::matrix::ortho(-half_width, half_width, -half_height, half_height, -1.0f, 1.0f);
            return update_result::changed;
        }
    }

    update_result _update_scale_factor() {
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

#pragma mark - renderer

ui::renderer::renderer(id<MTLDevice> const device) : base(std::make_shared<impl>(device)) {
    impl_ptr<impl>()->_root_node.renderable().set_renderer(*this);
}

ui::renderer::renderer(std::shared_ptr<impl> &&impl) : base(std::move(impl)) {
}

ui::renderer::renderer(std::nullptr_t) : base(nullptr) {
}

id<MTLDevice> ui::renderer::device() const {
    return impl_ptr<impl>()->device();
}

ui::uint_size const &ui::renderer::view_size() const {
    return impl_ptr<impl>()->_view_size;
}

ui::uint_size const &ui::renderer::drawable_size() const {
    return impl_ptr<impl>()->_drawable_size;
}

double ui::renderer::scale_factor() const {
    return impl_ptr<impl>()->_scale_factor;
}

simd::float4x4 const &ui::renderer::projection_matrix() const {
    return impl_ptr<impl>()->_projection_matrix;
}

id<MTLBuffer> ui::renderer::currentConstantBuffer() const {
    return impl_ptr<impl>()->currentConstantBuffer();
}

uint32_t ui::renderer::constant_buffer_offset() const {
    return impl_ptr<impl>()->constant_buffer_offset();
}

void ui::renderer::set_constant_buffer_offset(uint32_t const offset) {
    impl_ptr<impl>()->set_constant_buffer_offset(offset);
}

ui::node const &ui::renderer::root_node() const {
    return impl_ptr<impl>()->_root_node;
}

ui::node &ui::renderer::root_node() {
    return impl_ptr<impl>()->_root_node;
}

ui::view_renderable &ui::renderer::view_renderable() {
    if (!_view_renderable) {
        _view_renderable = ui::view_renderable{impl_ptr<view_renderable::impl>()};
    }
    return _view_renderable;
}

subject<ui::renderer, ui::renderer_method> &ui::renderer::subject() {
    return impl_ptr<impl>()->_subject;
}

ui::event_manager &ui::renderer::event_manager() {
    return impl_ptr<impl>()->_event_manager;
}

std::vector<ui::action> ui::renderer::actions() const {
    return impl_ptr<impl>()->_action.actions();
}

void ui::renderer::insert_action(ui::action action) {
    impl_ptr<impl>()->insert_action(std::move(action));
}

void ui::renderer::erase_action(ui::action const &action) {
    impl_ptr<impl>()->erase_action(action);
}

void ui::renderer::erase_action(ui::node const &target) {
    impl_ptr<impl>()->erase_action(target);
}

ui::collision_detector const &ui::renderer::collision_detector() const {
    return impl_ptr<impl>()->_detector;
}

ui::collision_detector &ui::renderer::collision_detector() {
    return impl_ptr<impl>()->_detector;
}
