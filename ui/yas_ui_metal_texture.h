//
//  yas_ui_metal_texture.h
//

#pragma once

#include <Metal/Metal.h>
#include "yas_base.h"
#include "yas_ui_metal_protocol.h"

namespace yas {
namespace ui {
    class uint_size;
    class metal_system;

    class metal_texture : public base {
       public:
        class impl;

        metal_texture(ui::uint_size size, bool const is_render_target);
        metal_texture(std::nullptr_t);
        
        virtual ~metal_texture() final;

        ui::uint_size size() const;
        id<MTLSamplerState> samplerState() const;
        id<MTLTexture> texture() const;
        id<MTLBuffer> argumentBuffer() const;
        MTLTextureType texture_type() const;
        MTLPixelFormat pixel_format() const;

        ui::metal_system const &metal_system();

        ui::metal_object &metal();

       private:
        ui::metal_object _metal_object = nullptr;
    };
}
}
