//
//  yas_ui_metal_texture.h
//

#pragma once

#include <Metal/Metal.h>
#include <cpp_utils/yas_objc_ptr.h>
#include <ui/yas_ui_gl_texture.h>
#include <ui/yas_ui_metal_dependency.h>

namespace yas::ui {
struct metal_texture : metal_object, gl_texture_interface {
    virtual ~metal_texture() final;

    [[nodiscard]] ui::uint_size size() const;
    [[nodiscard]] id<MTLSamplerState> samplerState() const;
    [[nodiscard]] id<MTLTexture> texture() const;
    [[nodiscard]] id<MTLBuffer> argumentBuffer() const;
    [[nodiscard]] MTLTextureType texture_type() const;
    [[nodiscard]] MTLPixelFormat pixel_format() const;
    [[nodiscard]] MTLTextureUsage texture_usage() const;

    void replace_data(uint_region const region, void const *data) override;

    [[nodiscard]] static std::shared_ptr<metal_texture> make_shared(ui::uint_size actual_size,
                                                                    ui::texture_usages_t const, ui::pixel_format const);

   private:
    ui::uint_size _size;
    MTLTextureUsage const _texture_usage;
    std::shared_ptr<ui::metal_system> _metal_system = nullptr;
    objc_ptr<id<MTLSamplerState>> _sampler_object;
    objc_ptr<id<MTLTexture>> _texture_object;
    objc_ptr<id<MTLArgumentEncoder>> _argument_encoder_object;
    std::shared_ptr<ui::metal_buffer> _argument_buffer = nullptr;
    MTLPixelFormat const _pixel_format = MTLPixelFormatBGRA8Unorm;
    MTLTextureType _target = MTLTextureType2D;

    metal_texture(ui::uint_size &&, ui::texture_usages_t const, ui::pixel_format const);

    metal_texture(metal_texture const &) = delete;
    metal_texture(metal_texture &&) = delete;
    metal_texture &operator=(metal_texture const &) = delete;
    metal_texture &operator=(metal_texture &&) = delete;

    ui::setup_metal_result metal_setup(std::shared_ptr<ui::metal_system> const &) override;
};
}  // namespace yas::ui
