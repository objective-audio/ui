//
//  yas_ui_metal_system.mm
//

#include "yas_ui_metal_system.h"
#include <cpp_utils/yas_each_index.h>
#include "yas_ui_mesh.h"
#include "yas_ui_mesh_data.h"
#include "yas_ui_metal_encode_info.h"
#include "yas_ui_metal_render_encoder.h"
#include "yas_ui_metal_texture.h"
#include "yas_ui_metal_types.h"
#include "yas_ui_metal_view.h"
#include "yas_ui_node.h"
#include "yas_ui_render_info.h"
#include "yas_ui_render_target.h"
#include "yas_ui_renderer.h"
#include "yas_ui_texture.h"

using namespace yas;

namespace yas::ui {
static auto constexpr _uniforms_buffer_allocating_unit = 1024 * 16;
static auto constexpr _uniforms_buffer_count = 3;

#if (!TARGET_OS_IPHONE && TARGET_OS_MAC)
static size_t constexpr _uniforms2d_required_align = 256;
#else
static size_t constexpr _uniforms2d_required_align = 4;
#endif
static size_t constexpr _uniforms2d_size = []() {
    size_t const reqired_align = MAX(ui::_uniforms2d_required_align, _Alignof(uniforms2d_t));
    size_t constexpr size = sizeof(uniforms2d_t);
    size_t const mod = size % reqired_align;
    if (mod > 0) {
        return size - mod + reqired_align;
    } else {
        return size;
    }
}();
}

#pragma mark - ui::metal_system::impl

struct ui::metal_system::impl {
    impl(id<MTLDevice> const device, uint32_t const sample_count) : _device(device), _sample_count(sample_count) {
        this->_command_queue.move_object([device newCommandQueue]);
        auto const bundle = objc_ptr<NSBundle *>([] { return [NSBundle bundleForClass:[YASUIMetalView class]]; });
        this->_default_library.move_object([device newDefaultLibraryWithBundle:bundle.object() error:nil]);
        this->_inflight_semaphore.move_object(dispatch_semaphore_create(ui::_uniforms_buffer_count));

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

        this->_pipeline_state_without_texture.move_object(
            [device newRenderPipelineStateWithDescriptor:pipelineStateDesc error:nil]);

        pipelineStateDesc.fragmentFunction = fragmentProgramWithTexture;

        this->_pipeline_state_with_texture.move_object(
            [device newRenderPipelineStateWithDescriptor:pipelineStateDesc error:nil]);
    }

    void prepare(ui::metal_system_ptr const &metal_system) {
        this->_weak_metal_system = metal_system;
    }

    void prepare_uniforms_buffer(uint32_t const uniforms_count) {
        bool needs_allocate = false;
        NSUInteger length = uniforms_count * ui::_uniforms2d_size;
        length = length - length % ui::_uniforms_buffer_allocating_unit + ui::_uniforms_buffer_allocating_unit;

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

    void view_configure(yas_objc_view *const objc_view) {
        if (![objc_view isKindOfClass:[YASUIMetalView class]]) {
            return;
        }

        auto view = (YASUIMetalView *const)objc_view;
        view.device = this->_device.object();
        view.sampleCount = this->_sample_count;
    }

    void view_render(yas_objc_view *const objc_view, ui::renderer_ptr const &renderer) {
        if (![objc_view isKindOfClass:[YASUIMetalView class]]) {
            return;
        }

        auto view = (YASUIMetalView *const)objc_view;

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

        this->_render_nodes(renderer, commandBuffer, renderPassDesc);

        [commandBuffer addCompletedHandler:[semaphore = this->_inflight_semaphore](id<MTLCommandBuffer> _Nonnull) {
            dispatch_semaphore_signal(semaphore.object());
        }];

        this->_uniforms_buffer_index = (this->_uniforms_buffer_index + 1) % ui::_uniforms_buffer_count;

        [commandBuffer presentDrawable:currentDrawable];
        [commandBuffer commit];
    }

    void mesh_encode(ui::mesh_ptr const &mesh, id<MTLRenderCommandEncoder> const encoder,
                     ui::metal_encode_info_ptr const &encode_info) {
        auto const currentUniformsBuffer = this->_uniforms_buffers[this->_uniforms_buffer_index].object();

        if (auto uniforms_ptr =
                (uniforms2d_t *)(&((uint8_t *)[currentUniformsBuffer contents])[this->_uniforms_buffer_offset])) {
            uniforms_ptr->matrix = mesh->renderable()->matrix();
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
        auto const renderable_mesh_data = mesh_data->renderable();

        [encoder setVertexBuffer:renderable_mesh_data->vertexBuffer()
                          offset:renderable_mesh_data->vertex_buffer_byte_offset()
                         atIndex:0];
        [encoder setVertexBuffer:currentUniformsBuffer offset:this->_uniforms_buffer_offset atIndex:1];

        [encoder drawIndexedPrimitives:to_mtl_primitive_type(mesh->primitive_type())
                            indexCount:mesh_data->index_count()
                             indexType:MTLIndexTypeUInt32
                           indexBuffer:renderable_mesh_data->indexBuffer()
                     indexBufferOffset:renderable_mesh_data->index_buffer_byte_offset()];

        this->_uniforms_buffer_offset += ui::_uniforms2d_size;
        assert(this->_uniforms_buffer_offset + ui::_uniforms2d_size < currentUniformsBuffer.length);
    }

    void push_render_target(ui::render_stackable_ptr const &stackable, ui::render_target_ptr const &render_target) {
        auto const renderable = render_target->renderable();
        stackable->push_encode_info(ui::metal_encode_info::make_shared(
            {.renderPassDescriptor = renderable->renderPassDescriptor(),
             .pipelineStateWithTexture = *this->_pipeline_state_with_texture,
             .pipelineStateWithoutTexture = *this->_pipeline_state_without_texture}));
    }

    id<MTLDevice> mtlDevice() {
        return this->_device.object();
    }

    uint32_t sample_count() {
        return this->_sample_count;
    }

    id<MTLRenderPipelineState> mtlRenderPipelineStateWithTexture() {
        return this->_pipeline_state_with_texture.object();
    }

    id<MTLRenderPipelineState> mtlRenderPipelineStateWithoutTexture() {
        return this->_pipeline_state_without_texture.object();
    }

    objc_ptr<id<MTLTexture>> make_mtl_texture(MTLTextureDescriptor *const textureDesc) {
        return objc_ptr_with_move_object([mtlDevice() newTextureWithDescriptor:textureDesc]);
    }

    objc_ptr<id<MTLSamplerState>> make_mtl_sampler_state(MTLSamplerDescriptor *const samplerDesc) {
        return objc_ptr_with_move_object([mtlDevice() newSamplerStateWithDescriptor:samplerDesc]);
    }

    objc_ptr<id<MTLArgumentEncoder>> make_mtl_argument_encoder() {
        return objc_ptr_with_move_object([*this->_fragment_function_with_texture newArgumentEncoderWithBufferIndex:0]);
    }

    objc_ptr<id<MTLBuffer>> make_mtl_buffer(std::size_t const length) {
        return objc_ptr_with_move_object(
            [mtlDevice() newBufferWithLength:length options:MTLResourceOptionCPUCacheModeDefault]);
    }

    objc_ptr<MPSImageGaussianBlur *> make_mtl_blur(double const sigma) {
        return objc_ptr_with_move_object([[MPSImageGaussianBlur alloc] initWithDevice:this->mtlDevice() sigma:sigma]);
    }

    std::size_t last_encoded_mesh_count() {
        return this->_last_encoded_mesh_count;
    }

   private:
    uint32_t _sample_count;

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

    objc_ptr<id<MTLFunction>> _fragment_function_with_texture;
    objc_ptr<id<MTLFunction>> _fragment_function_without_texture;
    objc_ptr<id<MTLFunction>> _vertex_function;

    std::size_t _last_encoded_mesh_count = 0;

    std::weak_ptr<metal_system> _weak_metal_system;

    void _render_nodes(ui::renderer_ptr const &renderer, id<MTLCommandBuffer> const commandBuffer,
                       MTLRenderPassDescriptor *const renderPassDesc) {
        auto metal_render_encoder = ui::metal_render_encoder::make_shared();
        render_stackable::cast(metal_render_encoder)
            ->push_encode_info(ui::metal_encode_info::make_shared(
                {.renderPassDescriptor = renderPassDesc,
                 .pipelineStateWithTexture = this->_multi_sample_pipeline_state_with_texture.object(),
                 .pipelineStateWithoutTexture = this->_multi_sample_pipeline_state_without_texture.object()}));

        auto metal_system = this->_weak_metal_system.lock();

        ui::render_info render_info{.detector = renderer->detector(),
                                    .render_encodable = render_encodable::cast(metal_render_encoder),
                                    .render_effectable = render_effectable::cast(metal_render_encoder),
                                    .render_stackable = render_stackable::cast(metal_render_encoder),
                                    .matrix = renderer->projection_matrix(),
                                    .mesh_matrix = renderer->projection_matrix()};

        renderer->root_node()->metal()->metal_setup(metal_system);
        renderer->root_node()->renderable()->build_render_info(render_info);

        auto result = metal_render_encoder->encode(metal_system, commandBuffer);
        this->_last_encoded_mesh_count = result.encoded_mesh_count;
    }
};

#pragma mark - ui::metal_system

ui::metal_system::metal_system(id<MTLDevice> const device, uint32_t const sample_count)
    : _impl(std::make_unique<impl>(device, sample_count)) {
}

ui::metal_system::~metal_system() = default;

std::size_t ui::metal_system::last_encoded_mesh_count() const {
    return this->_impl->last_encoded_mesh_count();
}

ui::makable_metal_system_ptr ui::metal_system::makable() {
    return std::dynamic_pointer_cast<makable_metal_system>(this->shared_from_this());
}

ui::renderable_metal_system_ptr ui::metal_system::renderable() {
    return std::dynamic_pointer_cast<renderable_metal_system>(this->shared_from_this());
}

ui::testable_metal_system_ptr ui::metal_system::testable() {
    return std::dynamic_pointer_cast<testable_metal_system>(this->shared_from_this());
}

void ui::metal_system::_prepare(metal_system_ptr const &metal_system) {
    this->_impl->prepare(metal_system);
}

void ui::metal_system::view_configure(yas_objc_view *const view) {
    this->_impl->view_configure(view);
}

void ui::metal_system::view_render(yas_objc_view *const view, ui::renderer_ptr const &renderer) {
    this->_impl->view_render(view, renderer);
}

void ui::metal_system::prepare_uniforms_buffer(uint32_t const uniforms_count) {
    this->_impl->prepare_uniforms_buffer(uniforms_count);
}

void ui::metal_system::mesh_encode(ui::mesh_ptr const &mesh, id<MTLRenderCommandEncoder> const commandEncoder,
                                   ui::metal_encode_info_ptr const &encode_info) {
    this->_impl->mesh_encode(mesh, commandEncoder, encode_info);
}

void ui::metal_system::push_render_target(ui::render_stackable_ptr const &stackable,
                                          ui::render_target_ptr const &render_target) {
    this->_impl->push_render_target(stackable, render_target);
}

objc_ptr<id<MTLTexture>> ui::metal_system::make_mtl_texture(MTLTextureDescriptor *const descriptor) {
    return this->_impl->make_mtl_texture(descriptor);
}

objc_ptr<id<MTLSamplerState>> ui::metal_system::make_mtl_sampler_state(MTLSamplerDescriptor *const descriptor) {
    return this->_impl->make_mtl_sampler_state(descriptor);
}

objc_ptr<id<MTLBuffer>> ui::metal_system::make_mtl_buffer(std::size_t const length) {
    return this->_impl->make_mtl_buffer(length);
}

objc_ptr<id<MTLArgumentEncoder>> ui::metal_system::make_mtl_argument_encoder() {
    return this->_impl->make_mtl_argument_encoder();
}

objc_ptr<MPSImageGaussianBlur *> ui::metal_system::make_mtl_blur(double const blur) {
    return this->_impl->make_mtl_blur(blur);
}

id<MTLDevice> ui::metal_system::mtlDevice() {
    return this->_impl->mtlDevice();
}

uint32_t ui::metal_system::sample_count() {
    return this->_impl->sample_count();
}

id<MTLRenderPipelineState> ui::metal_system::mtlRenderPipelineStateWithTexture() {
    return this->_impl->mtlRenderPipelineStateWithTexture();
}

id<MTLRenderPipelineState> ui::metal_system::mtlRenderPipelineStateWithoutTexture() {
    return this->_impl->mtlRenderPipelineStateWithoutTexture();
}

ui::metal_system_ptr ui::metal_system::make_shared(id<MTLDevice> const device) {
    return make_shared(device, 4);
}

ui::metal_system_ptr ui::metal_system::make_shared(id<MTLDevice> const device, uint32_t const sample_count) {
    auto shared = std::shared_ptr<metal_system>(new metal_system{device, sample_count});
    shared->_prepare(shared);
    return shared;
}
