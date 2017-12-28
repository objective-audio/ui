//
//  yas_ui_metal_system_protocol.h
//

#pragma once

#include <Metal/Metal.h>
#include <MetalPerformanceShaders/MetalPerformanceShaders.h>
#include "yas_objc_macros.h"
#include "yas_objc_ptr.h"
#include "yas_protocol.h"

namespace yas {
namespace ui {
    class renderer;
    class mesh;
    class metal_encode_info;
    class render_stackable;
    class render_target;

    struct renderable_metal_system : protocol {
        struct impl : protocol::impl {
            virtual void view_configure(yas_objc_view *const) = 0;
            virtual void view_render(yas_objc_view *const view, ui::renderer &) = 0;
            virtual void prepare_uniforms_buffer(uint32_t const uniforms_count) = 0;
            virtual void mesh_encode(ui::mesh &, id<MTLRenderCommandEncoder> const, ui::metal_encode_info const &) = 0;
            virtual void push_render_target(ui::render_stackable &, ui::render_target &) = 0;
        };

        explicit renderable_metal_system(std::shared_ptr<impl>);
        renderable_metal_system(std::nullptr_t);

        void view_configure(yas_objc_view *const);
        void view_render(yas_objc_view *const view, ui::renderer &);
        void prepare_uniforms_buffer(uint32_t const uniforms_count);
        void mesh_encode(ui::mesh &, id<MTLRenderCommandEncoder> const, ui::metal_encode_info const &);
        void push_render_target(ui::render_stackable &, ui::render_target &);
    };

    struct makable_metal_system : protocol {
        struct impl : protocol::impl {
            virtual objc_ptr<id<MTLTexture>> make_mtl_texture(MTLTextureDescriptor *const) = 0;
            virtual objc_ptr<id<MTLSamplerState>> make_mtl_sampler_state(MTLSamplerDescriptor *const) = 0;
            virtual objc_ptr<id<MTLBuffer>> make_mtl_buffer(std::size_t const length) = 0;
            virtual objc_ptr<id<MTLArgumentEncoder>> make_mtl_argument_encoder() = 0;
            virtual objc_ptr<MPSImageGaussianBlur *> make_mtl_blur(double const) = 0;
        };

        explicit makable_metal_system(std::shared_ptr<impl>);
        makable_metal_system(std::nullptr_t);

        objc_ptr<id<MTLTexture>> make_mtl_texture(MTLTextureDescriptor *const);
        objc_ptr<id<MTLSamplerState>> make_mtl_sampler_state(MTLSamplerDescriptor *const);
        objc_ptr<id<MTLBuffer>> make_mtl_buffer(std::size_t const length);
        objc_ptr<id<MTLArgumentEncoder>> make_mtl_argument_encoder();
        objc_ptr<MPSImageGaussianBlur *> make_mtl_blur(double const);
    };

    struct testable_metal_system : protocol {
        struct impl : protocol::impl {
            virtual id<MTLDevice> mtlDevice() = 0;
            virtual uint32_t sample_count() = 0;
            virtual id<MTLRenderPipelineState> mtlRenderPipelineStateWithTexture() = 0;
            virtual id<MTLRenderPipelineState> mtlRenderPipelineStateWithoutTexture() = 0;
        };

        explicit testable_metal_system(std::shared_ptr<impl>);
        testable_metal_system(std::nullptr_t);

        id<MTLDevice> mtlDevice();
        uint32_t sample_count();
        id<MTLRenderPipelineState> mtlRenderPipelineStateWithTexture();
        id<MTLRenderPipelineState> mtlRenderPipelineStateWithoutTexture();
    };
}
}
