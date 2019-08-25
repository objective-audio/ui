//
//  yas_ui_metal_system.h
//

#pragma once

#include <CoreGraphics/CoreGraphics.h>
#include "yas_ui_metal_system_protocol.h"
#include "yas_ui_ptr.h"

namespace yas::ui {

struct metal_system final : renderable_metal_system,
                            makable_metal_system,
                            testable_metal_system,
                            std::enable_shared_from_this<metal_system> {
    class impl;

    virtual ~metal_system();

    std::size_t last_encoded_mesh_count() const;

    ui::makable_metal_system_ptr makable();
    ui::renderable_metal_system_ptr renderable();
    ui::testable_metal_system_ptr testable();

    [[nodiscard]] static metal_system_ptr make_shared(id<MTLDevice> const);
    [[nodiscard]] static metal_system_ptr make_shared(id<MTLDevice> const, uint32_t const sample_count);

   private:
    std::shared_ptr<impl> _impl;

    metal_system(id<MTLDevice> const, uint32_t const sample_count);

    metal_system(metal_system const &) = delete;
    metal_system(metal_system &&) = delete;
    metal_system &operator=(metal_system const &) = delete;
    metal_system &operator=(metal_system &&) = delete;

    void _prepare(metal_system_ptr const &);

    void view_configure(yas_objc_view *const) override;
    void view_render(yas_objc_view *const view, ui::renderer_ptr const &) override;
    void prepare_uniforms_buffer(uint32_t const uniforms_count) override;
    void mesh_encode(ui::mesh_ptr const &, id<MTLRenderCommandEncoder> const,
                     ui::metal_encode_info_ptr const &) override;
    void push_render_target(ui::render_stackable_ptr const &, ui::render_target_ptr const &) override;

    objc_ptr<id<MTLTexture>> make_mtl_texture(MTLTextureDescriptor *const) override;
    objc_ptr<id<MTLSamplerState>> make_mtl_sampler_state(MTLSamplerDescriptor *const) override;
    objc_ptr<id<MTLBuffer>> make_mtl_buffer(std::size_t const length) override;
    objc_ptr<id<MTLArgumentEncoder>> make_mtl_argument_encoder() override;
    objc_ptr<MPSImageGaussianBlur *> make_mtl_blur(double const) override;

    id<MTLDevice> mtlDevice() override;
    uint32_t sample_count() override;
    id<MTLRenderPipelineState> mtlRenderPipelineStateWithTexture() override;
    id<MTLRenderPipelineState> mtlRenderPipelineStateWithoutTexture() override;
};
}  // namespace yas::ui
