//
//  yas_ui_metal_texture.h
//

#pragma once

#include <Metal/Metal.h>
#include <cpp_utils/yas_objc_ptr.h>
#include "yas_ui_metal_protocol.h"
#include "yas_ui_ptr.h"
#include "yas_ui_types.h"

namespace yas::ui {
struct metal_texture : metal_object {
    virtual ~metal_texture() final;

    ui::uint_size size() const;
    id<MTLSamplerState> samplerState() const;
    id<MTLTexture> texture() const;
    id<MTLBuffer> argumentBuffer() const;
    MTLTextureType texture_type() const;
    MTLPixelFormat pixel_format() const;
    MTLTextureUsage texture_usage() const;

    std::shared_ptr<ui::metal_system> const &metal_system();

    [[nodiscard]] static metal_texture_ptr make_shared(ui::uint_size actual_size, ui::texture_usages_t const,
                                                       ui::pixel_format const);

   private:
    ui::uint_size _size;
    MTLTextureUsage const _texture_usage;
    ui::metal_system_ptr _metal_system = nullptr;
    objc_ptr<id<MTLSamplerState>> _sampler_object;
    objc_ptr<id<MTLTexture>> _texture_object;
    objc_ptr<id<MTLArgumentEncoder>> _argument_encoder_object;
    objc_ptr<id<MTLBuffer>> _argument_buffer_object;
    MTLPixelFormat const _pixel_format = MTLPixelFormatBGRA8Unorm;
    MTLTextureType _target = MTLTextureType2D;

    metal_texture(ui::uint_size &&, ui::texture_usages_t const, ui::pixel_format const);

    ui::setup_metal_result metal_setup(std::shared_ptr<ui::metal_system> const &) override;
};
}  // namespace yas::ui
