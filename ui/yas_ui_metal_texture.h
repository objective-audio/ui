//
//  yas_ui_metal_texture.h
//

#pragma once

#include <Metal/Metal.h>
#include "yas_ui_metal_protocol.h"
#include "yas_ui_ptr.h"
#include "yas_ui_types.h"

namespace yas::ui {
class uint_size;
class metal_system;

struct metal_texture {
    class impl;

    virtual ~metal_texture() final;

    ui::uint_size size() const;
    id<MTLSamplerState> samplerState() const;
    id<MTLTexture> texture() const;
    id<MTLBuffer> argumentBuffer() const;
    MTLTextureType texture_type() const;
    MTLPixelFormat pixel_format() const;
    MTLTextureUsage texture_usage() const;

    std::shared_ptr<ui::metal_system> const &metal_system();

    ui::metal_object &metal();

    [[nodiscard]] static metal_texture_ptr make_shared(ui::uint_size actual_size, ui::texture_usages_t const,
                                                       ui::pixel_format const);

   private:
    std::shared_ptr<impl> _impl;

    ui::metal_object _metal_object = nullptr;

    metal_texture(ui::uint_size &&, ui::texture_usages_t const, ui::pixel_format const);
};
}  // namespace yas::ui
