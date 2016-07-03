//
//  yas_ui_metal_system.mm
//

#include "yas_each_index.h"
#include "yas_objc_ptr.h"
#include "yas_ui_mesh.h"
#include "yas_ui_mesh_data.h"
#include "yas_ui_metal_encode_info.h"
#include "yas_ui_metal_render_encoder.h"
#include "yas_ui_metal_system.h"
#include "yas_ui_metal_types.h"
#include "yas_ui_metal_view.h"
#include "yas_ui_node.h"
#include "yas_ui_render_info.h"
#include "yas_ui_renderer.h"
#include "yas_ui_texture.h"

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

        _render_nodes(renderer, commandBuffer, renderPassDesc);

        [commandBuffer addCompletedHandler:[semaphore = _inflight_semaphore](id<MTLCommandBuffer> _Nonnull) {
            dispatch_semaphore_signal(semaphore.object());
        }];

        _constant_buffer_index = (_constant_buffer_index + 1) % _inflight_buffer_count;

        [commandBuffer presentDrawable:view.currentDrawable];
        [commandBuffer commit];
    }

    void mesh_render(ui::mesh &mesh, id<MTLRenderCommandEncoder> const encoder,
                     ui::metal_encode_info const &encode_info) {
        auto &renderable_mesh = mesh.renderable();
        auto &mesh_data = mesh.mesh_data();
        auto &renderable_mesh_data = mesh_data.renderable();
        auto const vertex_buffer_byte_offset = renderable_mesh_data.vertex_buffer_byte_offset();
        auto const index_buffer_byte_offset = renderable_mesh_data.index_buffer_byte_offset();
        auto constant_buffer_offset = _constant_buffer_offset;
        auto const currentConstantBuffer = _constant_buffers[_constant_buffer_index].object();

        auto constant_ptr = (uint8_t *)[currentConstantBuffer contents];
        auto uniforms_ptr = (uniforms2d_t *)(&constant_ptr[constant_buffer_offset]);
        uniforms_ptr->matrix = renderable_mesh.matrix();
        uniforms_ptr->color = mesh.color();
        uniforms_ptr->use_mesh_color = mesh.is_use_mesh_color();

        if (auto &texture = mesh.texture()) {
            [encoder setFragmentBuffer:currentConstantBuffer offset:constant_buffer_offset atIndex:0];
            [encoder setRenderPipelineState:encode_info.pipelineState()];
            [encoder setFragmentTexture:texture.mtlTexture() atIndex:0];
            [encoder setFragmentSamplerState:texture.sampler() atIndex:0];
        } else {
            [encoder setRenderPipelineState:encode_info.pipelineStateWithoutTexture()];
        }

        [encoder setVertexBuffer:renderable_mesh_data.vertexBuffer() offset:vertex_buffer_byte_offset atIndex:0];
        [encoder setVertexBuffer:currentConstantBuffer offset:constant_buffer_offset atIndex:1];

        constant_buffer_offset += sizeof(uniforms2d_t);

        [encoder drawIndexedPrimitives:to_mtl_primitive_type(mesh.primitive_type())
                            indexCount:mesh_data.index_count()
                             indexType:MTLIndexTypeUInt32
                           indexBuffer:renderable_mesh_data.indexBuffer()
                     indexBufferOffset:index_buffer_byte_offset];

        assert(constant_buffer_offset + sizeof(uniforms2d_t) < _buffer_max_bytes);
        _constant_buffer_offset = constant_buffer_offset;
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

   private:
    void _render_nodes(ui::renderer &renderer, id<MTLCommandBuffer> const commandBuffer,
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

        metal_render_encoder.render(renderer, commandBuffer);
    }
};

#pragma mark - ui::metal_system

ui::metal_system::metal_system(id<MTLDevice> const device) : base(std::make_shared<impl>(device)) {
}

ui::metal_system::metal_system(std::nullptr_t) : base(nullptr) {
}

id<MTLDevice> ui::metal_system::device() const {
    return impl_ptr<impl>()->_device.object();
}

uint32_t ui::metal_system::sample_count() const {
    return impl_ptr<impl>()->_sample_count;
}

void ui::metal_system::view_render(yas_objc_view *const view, ui::renderer &renderer) {
    if ([view isKindOfClass:[YASUIMetalView class]]) {
        impl_ptr<impl>()->view_render((YASUIMetalView * const)view, renderer);
    }
}

void ui::metal_system::mesh_render(ui::mesh &mesh, id<MTLRenderCommandEncoder> const encoder,
                                   ui::metal_encode_info const &encode_info) {
    impl_ptr<impl>()->mesh_render(mesh, encoder, encode_info);
}
