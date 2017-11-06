//
//  yas_ui_metal_system.mm
//

#include "yas_each_index.h"
#include "yas_ui_mesh.h"
#include "yas_ui_mesh_data.h"
#include "yas_ui_metal_encode_info.h"
#include "yas_ui_metal_render_encoder.h"
#include "yas_ui_metal_system.h"
#include "yas_ui_metal_texture.h"
#include "yas_ui_metal_types.h"
#include "yas_ui_metal_view.h"
#include "yas_ui_node.h"
#include "yas_ui_render_info.h"
#include "yas_ui_renderer.h"
#include "yas_ui_texture.h"

using namespace yas;

namespace yas {
namespace ui {
    static auto constexpr _uniforms_buffer_allocating_unit = 1024 * 16;
    static auto constexpr _uniforms_buffer_count = 2;
}
}

#pragma mark - ui::metal_system::impl

struct ui::metal_system::impl : base::impl,
                                makable_metal_system::impl,
                                renderable_metal_system::impl,
                                testable_metal_system::impl {
    impl(id<MTLDevice> const device) : _device(device) {
        _command_queue.move_object([device newCommandQueue]);
        _default_library.move_object([device newDefaultLibrary]);
        _inflight_semaphore.move_object(dispatch_semaphore_create(_uniforms_buffer_count));

        auto defaultLibrary = _default_library.object();

        auto fragment_program_with_texture =
            make_objc_ptr([defaultLibrary newFunctionWithName:@"fragment2d_with_texture"]);
        auto fragment_program_without_texture =
            make_objc_ptr([defaultLibrary newFunctionWithName:@"fragment2d_without_texture"]);
        auto vertex_program = make_objc_ptr([defaultLibrary newFunctionWithName:@"vertex2d"]);

        auto fragmentProgramWithTexture = fragment_program_with_texture.object();
        auto fragmentProgramWithoutTexture = fragment_program_without_texture.object();
        auto vertexProgram = vertex_program.object();

        assert(fragmentProgramWithTexture);
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
        pipelineStateDesc.fragmentFunction = fragmentProgramWithTexture;
        [pipelineStateDesc.colorAttachments setObject:colorDesc atIndexedSubscript:0];
        pipelineStateDesc.depthAttachmentPixelFormat = _depth_pixel_format;
        pipelineStateDesc.stencilAttachmentPixelFormat = _stencil_pixel_format;

        _multi_sample_pipeline_state_with_texture.move_object(
            [device newRenderPipelineStateWithDescriptor:pipelineStateDesc error:nil]);

        pipelineStateDesc.fragmentFunction = fragmentProgramWithoutTexture;

        _multi_sample_pipeline_state_without_texture.move_object(
            [device newRenderPipelineStateWithDescriptor:pipelineStateDesc error:nil]);

        pipelineStateDesc.sampleCount = 1;

        _pipeline_state_without_texture.move_object(
            [device newRenderPipelineStateWithDescriptor:pipelineStateDesc error:nil]);

        pipelineStateDesc.fragmentFunction = fragmentProgramWithTexture;

        _pipeline_state_with_texture.move_object(
            [device newRenderPipelineStateWithDescriptor:pipelineStateDesc error:nil]);
    }

    void prepare_uniforms_buffer(uint32_t const uniforms_count) override {
        bool needs_allocate = false;
        NSUInteger length = uniforms_count * sizeof(uniforms2d_t);
        length = length - length % _uniforms_buffer_allocating_unit + _uniforms_buffer_allocating_unit;

        if (auto &current_buffer = _uniforms_buffers[_uniforms_buffer_index]) {
            id<MTLBuffer> currentBuffer = current_buffer.object();
            auto const prev_length = currentBuffer.length;
            if (prev_length < length) {
                needs_allocate = true;
            }
        } else {
            needs_allocate = true;
        }

        if (needs_allocate) {
            _uniforms_buffers[_uniforms_buffer_index].move_object(
                [_device.object() newBufferWithLength:length options:kNilOptions]);
        }
    }

    void view_configure(yas_objc_view *const objc_view) override {
        if (![objc_view isKindOfClass:[YASUIMetalView class]]) {
            return;
        }

        auto view = (YASUIMetalView * const)objc_view;
        view.device = _device.object();
        view.sampleCount = _sample_count;
    }

    void view_render(yas_objc_view *const objc_view, ui::renderer &renderer) override {
        if (![objc_view isKindOfClass:[YASUIMetalView class]]) {
            return;
        }

        auto view = (YASUIMetalView * const)objc_view;

        auto renderPassDesc = view.currentRenderPassDescriptor;
        auto currentDrawable = view.currentDrawable;

        if (!renderPassDesc || !currentDrawable) {
            return;
        }

        dispatch_semaphore_wait(_inflight_semaphore.object(), DISPATCH_TIME_FOREVER);

        auto command_buffer = make_objc_ptr<id<MTLCommandBuffer>>([commandQueue = _command_queue.object()]() {
            return [commandQueue commandBuffer];
        });
        auto commandBuffer = command_buffer.object();

        _uniforms_buffer_offset = 0;

        _render_nodes(renderer, commandBuffer, renderPassDesc);

        [commandBuffer addCompletedHandler:[semaphore = _inflight_semaphore](id<MTLCommandBuffer> _Nonnull) {
            dispatch_semaphore_signal(semaphore.object());
        }];

        _uniforms_buffer_index = (_uniforms_buffer_index + 1) % _uniforms_buffer_count;

        [commandBuffer presentDrawable:currentDrawable];
        [commandBuffer commit];
    }

    void mesh_encode(ui::mesh &mesh, id<MTLRenderCommandEncoder> const encoder,
                     ui::metal_encode_info const &encode_info) override {
        auto const currentUniformsBuffer = _uniforms_buffers[_uniforms_buffer_index].object();

        if (auto uniforms_ptr =
                (uniforms2d_t *)(&((uint8_t *)[currentUniformsBuffer contents])[_uniforms_buffer_offset])) {
            uniforms_ptr->matrix = mesh.renderable().matrix();
            uniforms_ptr->color = mesh.color();
            uniforms_ptr->use_mesh_color = mesh.is_use_mesh_color();
        }

        if (auto &texture = mesh.texture()) {
            [encoder setFragmentBuffer:currentUniformsBuffer offset:_uniforms_buffer_offset atIndex:0];
            [encoder setRenderPipelineState:encode_info.pipelineStateWithTexture()];
            [encoder setFragmentTexture:texture.metal_texture().texture() atIndex:0];
            [encoder setFragmentSamplerState:texture.metal_texture().samplerState() atIndex:0];
        } else {
            [encoder setRenderPipelineState:encode_info.pipelineStateWithoutTexture()];
        }

        auto &mesh_data = mesh.mesh_data();
        auto &renderable_mesh_data = mesh_data.renderable();

        [encoder setVertexBuffer:renderable_mesh_data.vertexBuffer()
                          offset:renderable_mesh_data.vertex_buffer_byte_offset()
                         atIndex:0];
        [encoder setVertexBuffer:currentUniformsBuffer offset:_uniforms_buffer_offset atIndex:1];

        [encoder drawIndexedPrimitives:to_mtl_primitive_type(mesh.primitive_type())
                            indexCount:mesh_data.index_count()
                             indexType:MTLIndexTypeUInt32
                           indexBuffer:renderable_mesh_data.indexBuffer()
                     indexBufferOffset:renderable_mesh_data.index_buffer_byte_offset()];

        _uniforms_buffer_offset += sizeof(uniforms2d_t);
        assert(_uniforms_buffer_offset + sizeof(uniforms2d_t) < currentUniformsBuffer.length);
    }

    id<MTLDevice> mtlDevice() override {
        return _device.object();
    }

    uint32_t sample_count() override {
        return _sample_count;
    }

    id<MTLRenderPipelineState> mtlRenderPipelineStateWithTexture() override {
        return _pipeline_state_with_texture.object();
    }

    id<MTLRenderPipelineState> mtlRenderPipelineStateWithoutTexture() override {
        return _pipeline_state_without_texture.object();
    }

    objc_ptr<id<MTLTexture>> make_mtl_texture(MTLTextureDescriptor *const textureDesc) override {
        return make_objc_ptr([mtlDevice() newTextureWithDescriptor:textureDesc]);
    }

    objc_ptr<id<MTLSamplerState>> make_mtl_sampler_state(MTLSamplerDescriptor *const samplerDesc) override {
        return make_objc_ptr([mtlDevice() newSamplerStateWithDescriptor:samplerDesc]);
    }

    objc_ptr<id<MTLBuffer>> make_mtl_buffer(std::size_t const length) override {
        return make_objc_ptr([mtlDevice() newBufferWithLength:length options:MTLResourceOptionCPUCacheModeDefault]);
    }

   private:
    uint32_t _sample_count = 4;

    objc_ptr<id<MTLBuffer>> _uniforms_buffers[_uniforms_buffer_count];
    uint8_t _uniforms_buffer_index = 0;
    uint32_t _uniforms_buffer_offset = 0;

    MTLPixelFormat _depth_pixel_format = MTLPixelFormatInvalid;
    MTLPixelFormat _stencil_pixel_format = MTLPixelFormatInvalid;

    objc_ptr<id<MTLDevice>> _device;
    objc_ptr<id<MTLCommandQueue>> _command_queue;
    objc_ptr<id<MTLLibrary>> _default_library;

    objc_ptr<dispatch_semaphore_t> _inflight_semaphore;

    objc_ptr<id<MTLRenderPipelineState>> _multi_sample_pipeline_state_with_texture;
    objc_ptr<id<MTLRenderPipelineState>> _multi_sample_pipeline_state_without_texture;
    objc_ptr<id<MTLRenderPipelineState>> _pipeline_state_with_texture;
    objc_ptr<id<MTLRenderPipelineState>> _pipeline_state_without_texture;

    void _render_nodes(ui::renderer &renderer, id<MTLCommandBuffer> const commandBuffer,
                       MTLRenderPassDescriptor *const renderPassDesc) {
        ui::metal_render_encoder metal_render_encoder;
        metal_render_encoder.push_encode_info(
            {{.renderPassDescriptor = renderPassDesc,
              .pipelineStateWithTexture = _multi_sample_pipeline_state_with_texture.object(),
              .pipelineStateWithoutTexture = _multi_sample_pipeline_state_without_texture.object()}});

        ui::render_info render_info{.detector = renderer.detector(),
                                    .render_encodable = metal_render_encoder.encodable(),
                                    .matrix = renderer.projection_matrix(),
                                    .mesh_matrix = renderer.projection_matrix()};

        auto metal_system = cast<ui::metal_system>();

        renderer.root_node().metal().metal_setup(metal_system);
        renderer.root_node().renderable().build_render_info(render_info);

        for (auto &batch : render_info.batches) {
            batch.metal().metal_setup(metal_system);
        }

        metal_render_encoder.encode(metal_system, commandBuffer);
    }
};

#pragma mark - ui::metal_system

ui::metal_system::metal_system(id<MTLDevice> const device) : base(std::make_shared<impl>(device)) {
}

ui::metal_system::metal_system(std::nullptr_t) : base(nullptr) {
}

ui::metal_system::~metal_system() = default;

ui::makable_metal_system &ui::metal_system::makable() {
    if (!_makable) {
        _makable = ui::makable_metal_system{impl_ptr<ui::makable_metal_system::impl>()};
    }

    return _makable;
}

ui::renderable_metal_system &ui::metal_system::renderable() {
    if (!_renderable) {
        _renderable = ui::renderable_metal_system{impl_ptr<ui::renderable_metal_system::impl>()};
    }

    return _renderable;
}

#if YAS_TEST
ui::testable_metal_system ui::metal_system::testable() {
    return ui::testable_metal_system{impl_ptr<ui::testable_metal_system::impl>()};
}
#endif
