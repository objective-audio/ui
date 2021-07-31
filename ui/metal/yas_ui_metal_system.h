//
//  yas_ui_metal_system.h
//

#pragma once

#include <CoreGraphics/CoreGraphics.h>
#include <ui/yas_ui_gl_texture.h>
#include <ui/yas_ui_metal_encoder_dependency.h>
#include <ui/yas_ui_metal_system_protocol.h>
#include <ui/yas_ui_metal_view_controller_dependency_objc.h>

namespace yas::ui {
struct metal_system final : renderer_system_interface,
                            renderable_metal_system,
                            makable_metal_system,
                            testable_metal_system,
                            view_metal_system_interface,
                            metal_encoder_system_interface {
    [[nodiscard]] std::size_t last_encoded_mesh_count() const;

    [[nodiscard]] std::shared_ptr<metal_buffer> make_metal_buffer(std::size_t const length);

    using make_texture_result = result<std::shared_ptr<ui::metal_texture>, setup_metal_error>;
    [[nodiscard]] make_texture_result make_texture(ui::uint_size const actual_size, ui::texture_usages_t const,
                                                   ui::pixel_format const);

    [[nodiscard]] static std::shared_ptr<metal_system> make_shared(id<MTLDevice> const, YASUIMetalView *const);
    [[nodiscard]] static std::shared_ptr<metal_system> make_shared(id<MTLDevice> const, YASUIMetalView *const,
                                                                   uint32_t const sample_count);

   private:
    uint32_t _sample_count;

    static auto constexpr _uniforms_buffer_count = 3;
    objc_ptr<id<MTLBuffer>> _uniforms_buffers[_uniforms_buffer_count];
    uint8_t _uniforms_buffer_index = 0;
    uint32_t _uniforms_buffer_offset = 0;

    MTLPixelFormat _depth_pixel_format = MTLPixelFormatInvalid;
    MTLPixelFormat _stencil_pixel_format = MTLPixelFormatInvalid;

    objc_ptr<id<MTLDevice>> _device;
    objc_ptr<id<MTLCommandQueue>> _command_queue;
    objc_ptr<id<MTLLibrary>> _default_library;

    objc_ptr<YASUIMetalView *> _metal_view;

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

    metal_system(id<MTLDevice> const, YASUIMetalView *const, uint32_t const sample_count);

    metal_system(metal_system const &) = delete;
    metal_system(metal_system &&) = delete;
    metal_system &operator=(metal_system const &) = delete;
    metal_system &operator=(metal_system &&) = delete;

    void view_render(std::shared_ptr<ui::render_info_detector_interface> const &,
                     simd::float4x4 const &projection_matrix, std::shared_ptr<ui::node> const &) override;
    void prepare_uniforms_buffer(uint32_t const uniforms_count) override;
    void mesh_encode(std::shared_ptr<mesh> const &, id<MTLRenderCommandEncoder> const,
                     std::shared_ptr<metal_encode_info> const &) override;
    void push_render_target(std::shared_ptr<render_stackable> const &, ui::render_target const *) override;

    objc_ptr<id<MTLTexture>> make_mtl_texture(MTLTextureDescriptor *const) override;
    objc_ptr<id<MTLSamplerState>> make_mtl_sampler_state(MTLSamplerDescriptor *const) override;
    objc_ptr<id<MTLArgumentEncoder>> make_mtl_argument_encoder() override;
    objc_ptr<MPSImageGaussianBlur *> make_mtl_blur(double const) override;

    [[nodiscard]] id<MTLDevice> mtlDevice() override;
    [[nodiscard]] uint32_t sample_count() override;

    id<MTLRenderPipelineState> mtlRenderPipelineStateWithTexture() override;
    id<MTLRenderPipelineState> mtlRenderPipelineStateWithoutTexture() override;

    void _render_nodes(std::shared_ptr<ui::render_info_detector_interface> const &,
                       simd::float4x4 const &projection_matrix, std::shared_ptr<ui::node> const &,
                       id<MTLCommandBuffer> const, MTLRenderPassDescriptor *consts);
};
}  // namespace yas::ui
