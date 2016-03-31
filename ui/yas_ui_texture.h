//
//  yas_ui_texture.h
//

#pragma once

#include <Metal/Metal.h>
#include <simd/simd.h>
#include "yas_base.h"
#include "yas_result.h"
#include "yas_ui_metal_protocol.h"
#include "yas_ui_types.h"

namespace yas {
namespace ui {
    class image;

    class texture : public base {
        using super_class = base;

       public:
        enum class draw_image_error {
            unknown,
            image_is_null,
            no_setup,
            out_of_range,
        };

        using draw_image_result = result<uint_region, draw_image_error>;

        texture(uint_size const point_size, Float64 const scale_factor,
                MTLPixelFormat const pixel_format = MTLPixelFormatRGBA8Unorm);
        texture(std::nullptr_t);

        bool operator==(texture const &) const;
        bool operator!=(texture const &) const;

        id<MTLSamplerState> sampler() const;
        id<MTLTexture> mtlTexture() const;
        MTLTextureType target() const;
        uint_size point_size() const;
        uint_size actual_size() const;
        Float64 scale_factor() const;
        UInt32 depth() const;
        MTLPixelFormat pixel_format() const;
        bool has_alpha() const;

        draw_image_result add_image(image const &image);
        draw_image_result replace_image(image const &image, uint_origin const actual_origin);

        ui::metal_object metal();

        class impl;
    };
}

template <>
ui::texture cast(base const &);

std::string to_string(ui::texture::draw_image_error const);
}
