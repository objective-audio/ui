//
//  yas_ui_metal_system_protocol.h
//

#pragma once

#include <Metal/Metal.h>
#include <MetalPerformanceShaders/MetalPerformanceShaders.h>
#include <cpp_utils/yas_objc_ptr.h>
#include <objc_utils/yas_objc_macros.h>
#include <ui/yas_ui_mesh.h>
#include <ui/yas_ui_metal_encode_info.h>
#include <ui/yas_ui_render_info_dependency.h>

namespace yas::ui {
struct renderable_metal_system {
    virtual ~renderable_metal_system() = default;

    virtual void view_configure(yas_objc_view *const) = 0;
    virtual void view_render(yas_objc_view *const view, ui::renderer const *) = 0;
    virtual void prepare_uniforms_buffer(uint32_t const uniforms_count) = 0;
    virtual void mesh_encode(ui::mesh_ptr const &, id<MTLRenderCommandEncoder> const,
                             ui::metal_encode_info_ptr const &) = 0;
    virtual void push_render_target(ui::render_stackable_ptr const &, ui::render_target const *) = 0;

    static renderable_metal_system_ptr cast(renderable_metal_system_ptr const &system) {
        return system;
    }
};

struct makable_metal_system {
    virtual ~makable_metal_system() = default;

    [[nodiscard]] virtual objc_ptr<id<MTLTexture>> make_mtl_texture(MTLTextureDescriptor *const) = 0;
    [[nodiscard]] virtual objc_ptr<id<MTLSamplerState>> make_mtl_sampler_state(MTLSamplerDescriptor *const) = 0;
    [[nodiscard]] virtual objc_ptr<id<MTLBuffer>> make_mtl_buffer(std::size_t const length) = 0;
    [[nodiscard]] virtual objc_ptr<id<MTLArgumentEncoder>> make_mtl_argument_encoder() = 0;
    [[nodiscard]] virtual objc_ptr<MPSImageGaussianBlur *> make_mtl_blur(double const) = 0;

    static makable_metal_system_ptr cast(makable_metal_system_ptr const &system) {
        return system;
    }
};

struct testable_metal_system {
    virtual ~testable_metal_system() = default;

    [[nodiscard]] virtual id<MTLDevice> mtlDevice() = 0;
    [[nodiscard]] virtual uint32_t sample_count() = 0;
    [[nodiscard]] virtual id<MTLRenderPipelineState> mtlRenderPipelineStateWithTexture() = 0;
    [[nodiscard]] virtual id<MTLRenderPipelineState> mtlRenderPipelineStateWithoutTexture() = 0;

    static testable_metal_system_ptr cast(testable_metal_system_ptr const &system) {
        return system;
    }
};
}  // namespace yas::ui