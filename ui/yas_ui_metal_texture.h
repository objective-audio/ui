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

struct metal_texture : metal_object, std::enable_shared_from_this<metal_texture> {
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

    ui::metal_object_ptr metal();

    [[nodiscard]] static metal_texture_ptr make_shared(ui::uint_size actual_size, ui::texture_usages_t const,
                                                       ui::pixel_format const);

   private:
    std::unique_ptr<impl> _impl;

    metal_texture(ui::uint_size &&, ui::texture_usages_t const, ui::pixel_format const);

    ui::setup_metal_result metal_setup(std::shared_ptr<ui::metal_system> const &) override;
};
}  // namespace yas::ui
