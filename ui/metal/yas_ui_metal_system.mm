//
//  yas_ui_metal_system.mm
//

#include "yas_ui_metal_system.h"
#include <cpp_utils/yas_each_index.h>
#include <cpp_utils/yas_unless.h>
#include <ui/yas_ui_mesh.h>
#include <ui/yas_ui_mesh_data.h>
#include <ui/yas_ui_metal_buffer.h>
#include <ui/yas_ui_metal_encode_info.h>
#include <ui/yas_ui_metal_encoder.h>
#include <ui/yas_ui_metal_texture.h>
#include <ui/yas_ui_metal_types.h>
#include <ui/yas_ui_metal_view.h>
#include <ui/yas_ui_node.h>
#include <ui/yas_ui_render_info.h>
#include <ui/yas_ui_render_target.h>
#include <ui/yas_ui_renderer.h>
#include <ui/yas_ui_texture.h>

using namespace yas;
using namespace yas::ui;

namespace yas::ui {
static auto constexpr _uniforms_buffer_allocating_unit = 1024 * 16;

#if (TARGET_OS_IPHONE && TARGET_OS_EMBEDDED)
static size_t constexpr _uniforms2d_required_align = 4;
#else
static size_t constexpr _uniforms2d_required_align = 256;
#endif
static size_t constexpr _uniforms2d_size = []() {
    size_t const reqired_align = MAX(_uniforms2d_required_align, _Alignof(uniforms2d_t));
    size_t constexpr size = sizeof(uniforms2d_t);
    size_t const mod = size % reqired_align;
    if (mod > 0) {
        return size - mod + reqired_align;
    } else {
        return size;
    }
}();
}

#pragma mark - metal_system

metal_system::metal_system(id<MTLDevice> const device, YASUIMetalView *const metalView, uint32_t const sample_count)
    : _device(device), _metal_view(metalView), _sample_count(sample_count) {
    this->_command_queue.move_object([device newCommandQueue]);
    auto const bundle = objc_ptr<NSBundle *>([] { return [NSBundle bundleForClass:[YASUIMetalView class]]; });
    this->_default_library.move_object([device newDefaultLibraryWithBundle:bundle.object() error:nil]);
    this->_inflight_semaphore.move_object(dispatch_semaphore_create(metal_system::_uniforms_buffer_count));

    auto defaultLibrary = this->_default_library.object();

    this->_fragment_function_with_texture =
        objc_ptr_with_move_object([defaultLibrary newFunctionWithName:@"fragment2d_with_texture"]);
    this->_fragment_function_without_texture =
        objc_ptr_with_move_object([defaultLibrary newFunctionWithName:@"fragment2d_without_texture"]);
    this->_vertex_function = objc_ptr_with_move_object([defaultLibrary newFunctionWithName:@"vertex2d"]);

    auto fragmentProgramWithTexture = this->_fragment_function_with_texture.object();
    auto fragmentProgramWithoutTexture = this->_fragment_function_without_texture.object();
    auto vertexProgram = this->_vertex_function.object();

    assert(fragmentProgramWithTexture);
    assert(fragmentProgramWithoutTexture);
    assert(vertexProgram);

    auto color_desc = objc_ptr_with_move_object([MTLRenderPipelineColorAttachmentDescriptor new]);
    auto colorDesc = color_desc.object();
    colorDesc.pixelFormat = MTLPixelFormatBGRA8Unorm;
    colorDesc.blendingEnabled = YES;
    colorDesc.rgbBlendOperation = MTLBlendOperationAdd;
    colorDesc.alphaBlendOperation = MTLBlendOperationAdd;
    colorDesc.sourceRGBBlendFactor = MTLBlendFactorOne;
    colorDesc.sourceAlphaBlendFactor = MTLBlendFactorOne;
    colorDesc.destinationRGBBlendFactor = MTLBlendFactorOneMinusSourceAlpha;
    colorDesc.destinationAlphaBlendFactor = MTLBlendFactorOneMinusSourceAlpha;

    auto pipeline_state_desc = objc_ptr_with_move_object([MTLRenderPipelineDescriptor new]);
    auto pipelineStateDesc = pipeline_state_desc.object();
    pipelineStateDesc.sampleCount = this->_sample_count;
    pipelineStateDesc.vertexFunction = vertexProgram;
    pipelineStateDesc.fragmentFunction = fragmentProgramWithTexture;
    [pipelineStateDesc.colorAttachments setObject:colorDesc atIndexedSubscript:0];
    pipelineStateDesc.depthAttachmentPixelFormat = this->_depth_pixel_format;
    pipelineStateDesc.stencilAttachmentPixelFormat = this->_stencil_pixel_format;

    this->_multi_sample_pipeline_state_with_texture.move_object(
        [device newRenderPipelineStateWithDescriptor:pipelineStateDesc error:nil]);

    pipelineStateDesc.fragmentFunction = fragmentProgramWithoutTexture;

    this->_multi_sample_pipeline_state_without_texture.move_object(
        [device newRenderPipelineStateWithDescriptor:pipelineStateDesc error:nil]);

    pipelineStateDesc.sampleCount = 1;

    this->_pipeline_state_without_texture.move_object([device newRenderPipelineStateWithDescriptor:pipelineStateDesc
                                                                                             error:nil]);

    pipelineStateDesc.fragmentFunction = fragmentProgramWithTexture;

    this->_pipeline_state_with_texture.move_object([device newRenderPipelineStateWithDescriptor:pipelineStateDesc
                                                                                          error:nil]);
}

std::size_t metal_system::last_encoded_mesh_count() const {
    return this->_last_encoded_mesh_count;
}

std::shared_ptr<metal_buffer> metal_system::make_metal_buffer(std::size_t const length) {
    return metal_buffer::make_shared(this->mtlDevice(), length);
}

metal_system::make_texture_result metal_system::make_texture(ui::uint_size const actual_size,
                                                             ui::texture_usages_t const usages,
                                                             ui::pixel_format const pixel_format) {
    auto texture = metal_texture::make_shared(actual_size, usages, pixel_format);

    if (auto result = texture->metal_setup(this->_weak_metal_system.lock())) {
        return make_texture_result{std::move(texture)};
    } else {
        return make_texture_result{result.error()};
    }
}

void metal_system::view_render(std::shared_ptr<ui::detector_for_render_info> const &detector,
                               simd::float4x4 const &projection_matrix, std::shared_ptr<ui::node> const &node) {
    if (!this->_metal_view) {
        return;
    }

    auto const *view = this->_metal_view.object();
    auto renderPassDesc = view.currentRenderPassDescriptor;
    auto currentDrawable = view.currentDrawable;

    if (!renderPassDesc || !currentDrawable) {
        return;
    }

    dispatch_semaphore_wait(this->_inflight_semaphore.object(), DISPATCH_TIME_FOREVER);

    auto command_buffer = objc_ptr<id<MTLCommandBuffer>>(
        [commandQueue = this->_command_queue.object()]() { return [commandQueue commandBuffer]; });
    auto commandBuffer = command_buffer.object();

    this->_uniforms_buffer_offset = 0;

    this->_render_nodes(detector, projection_matrix, node, commandBuffer, renderPassDesc);

    [commandBuffer addCompletedHandler:[semaphore = this->_inflight_semaphore](id<MTLCommandBuffer> _Nonnull) {
        dispatch_semaphore_signal(semaphore.object());
    }];

    this->_uniforms_buffer_index = (this->_uniforms_buffer_index + 1) % metal_system::_uniforms_buffer_count;

    [commandBuffer presentDrawable:currentDrawable];
    [commandBuffer commit];
}

void metal_system::prepare_uniforms_buffer(uint32_t const uniforms_count) {
    bool needs_allocate = false;
    NSUInteger length = uniforms_count * _uniforms2d_size;
    length = length - length % _uniforms_buffer_allocating_unit + _uniforms_buffer_allocating_unit;

    if (auto &current_buffer = this->_uniforms_buffers[this->_uniforms_buffer_index]) {
        id<MTLBuffer> currentBuffer = current_buffer.object();
        auto const prev_length = currentBuffer.length;
        if (prev_length < length) {
            needs_allocate = true;
        }
    } else {
        needs_allocate = true;
    }

    if (needs_allocate) {
        this->_uniforms_buffers[this->_uniforms_buffer_index].move_object(
            [this->_device.object() newBufferWithLength:length options:kNilOptions]);
    }
}

void metal_system::mesh_encode(std::shared_ptr<mesh> const &mesh, id<MTLRenderCommandEncoder> const encoder,
                               std::shared_ptr<metal_encode_info> const &encode_info) {
    auto const currentUniformsBuffer = this->_uniforms_buffers[this->_uniforms_buffer_index].object();

    if (auto uniforms_ptr =
            (uniforms2d_t *)(&((uint8_t *)[currentUniformsBuffer contents])[this->_uniforms_buffer_offset])) {
        uniforms_ptr->matrix = renderable_mesh::cast(mesh)->matrix();
        uniforms_ptr->color = mesh->color();
        uniforms_ptr->use_mesh_color = mesh->is_use_mesh_color();
    }

    if (auto &texture = mesh->texture()) {
        [encoder setRenderPipelineState:encode_info->pipelineStateWithTexture()];
        [encoder setFragmentBuffer:texture->metal_texture()->argumentBuffer() offset:0 atIndex:0];
    } else {
        [encoder setRenderPipelineState:encode_info->pipelineStateWithoutTexture()];
    }

    auto &mesh_data = mesh->mesh_data();

    [encoder setVertexBuffer:mesh_data->vertexBuffer() offset:mesh_data->vertex_buffer_byte_offset() atIndex:0];
    [encoder setVertexBuffer:currentUniformsBuffer offset:this->_uniforms_buffer_offset atIndex:1];

    [encoder drawIndexedPrimitives:to_mtl_primitive_type(mesh->primitive_type())
                        indexCount:mesh_data->index_count()
                         indexType:MTLIndexTypeUInt32
                       indexBuffer:mesh_data->indexBuffer()
                 indexBufferOffset:mesh_data->index_buffer_byte_offset()];

    this->_uniforms_buffer_offset += _uniforms2d_size;
    assert(this->_uniforms_buffer_offset + _uniforms2d_size < currentUniformsBuffer.length);
}

void metal_system::push_render_target(std::shared_ptr<render_stackable> const &stackable,
                                      render_target const *render_target) {
    stackable->push_encode_info(
        metal_encode_info::make_shared({.renderPassDescriptor = render_target->renderPassDescriptor(),
                                        .pipelineStateWithTexture = *this->_pipeline_state_with_texture,
                                        .pipelineStateWithoutTexture = *this->_pipeline_state_without_texture}));
}

objc_ptr<id<MTLTexture>> metal_system::make_mtl_texture(MTLTextureDescriptor *const descriptor) {
    return objc_ptr_with_move_object([mtlDevice() newTextureWithDescriptor:descriptor]);
}

objc_ptr<id<MTLSamplerState>> metal_system::make_mtl_sampler_state(MTLSamplerDescriptor *const descriptor) {
    return objc_ptr_with_move_object([mtlDevice() newSamplerStateWithDescriptor:descriptor]);
}

objc_ptr<id<MTLArgumentEncoder>> metal_system::make_mtl_argument_encoder() {
    return objc_ptr_with_move_object([*this->_fragment_function_with_texture newArgumentEncoderWithBufferIndex:0]);
}

objc_ptr<MPSImageGaussianBlur *> metal_system::make_mtl_blur(double const blur) {
    return objc_ptr_with_move_object([[MPSImageGaussianBlur alloc] initWithDevice:this->mtlDevice() sigma:blur]);
}

id<MTLDevice> metal_system::mtlDevice() {
    return this->_device.object();
}

uint32_t metal_system::sample_count() {
    return this->_sample_count;
}

id<MTLRenderPipelineState> metal_system::mtlRenderPipelineStateWithTexture() {
    return this->_pipeline_state_with_texture.object();
}

id<MTLRenderPipelineState> metal_system::mtlRenderPipelineStateWithoutTexture() {
    return this->_pipeline_state_without_texture.object();
}

void metal_system::_render_nodes(std::shared_ptr<ui::detector_for_render_info> const &detector,
                                 simd::float4x4 const &projection_matrix, std::shared_ptr<ui::node> const &node,
                                 id<MTLCommandBuffer> const commandBuffer,
                                 MTLRenderPassDescriptor *const renderPassDesc) {
    auto const metal_render_encoder = metal_encoder::make_shared();
    render_stackable::cast(metal_render_encoder)
        ->push_encode_info(metal_encode_info::make_shared(
            {.renderPassDescriptor = renderPassDesc,
             .pipelineStateWithTexture = this->_multi_sample_pipeline_state_with_texture.object(),
             .pipelineStateWithoutTexture = this->_multi_sample_pipeline_state_without_texture.object()}));

    auto const metal_system = this->_weak_metal_system.lock();

    render_info render_info{.detector = detector,
                            .render_encodable = render_encodable::cast(metal_render_encoder),
                            .render_effectable = render_effectable::cast(metal_render_encoder),
                            .render_stackable = render_stackable::cast(metal_render_encoder),
                            .matrix = projection_matrix,
                            .mesh_matrix = projection_matrix};

    node->metal_setup(metal_system);
    renderable_node::cast(node)->build_render_info(render_info);

    auto const result = metal_render_encoder->encode(metal_system, commandBuffer);
    this->_last_encoded_mesh_count = result.encoded_mesh_count;
}

std::shared_ptr<metal_system> metal_system::make_shared(id<MTLDevice> const device, YASUIMetalView *const metalView) {
    return make_shared(device, metalView, 1);
}

std::shared_ptr<metal_system> metal_system::make_shared(id<MTLDevice> const device, YASUIMetalView *const metalView,
                                                        uint32_t const sample_count) {
    auto shared = std::shared_ptr<metal_system>(new metal_system{device, metalView, sample_count});
    shared->_weak_metal_system = shared;
    return shared;
}
