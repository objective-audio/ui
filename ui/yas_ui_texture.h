//
//  yas_ui_texture.h
//

#pragma once

#include "yas_base.h"
#include "yas_result.h"
#include "yas_ui_metal_protocol.h"
#include "yas_ui_metal_system.h"
#include "yas_ui_types.h"

namespace yas {
namespace ui {
    class image;
    class metal_texture;

    class texture : public base {
       public:
        class impl;

        struct args {
            ui::metal_system metal_system;
            ui::uint_size point_size;
            double scale_factor = 1.0;
            uint32_t draw_padding = 2;
            ui::texture_usages_t usages = {texture_usage::shader_read};
            ui::pixel_format pixel_format = ui::pixel_format::rgba8_unorm;
        };

        enum class draw_image_error {
            unknown,
            image_is_null,
            no_setup,
            out_of_range,
        };

        using draw_image_result = result<uint_region, draw_image_error>;

        texture(std::nullptr_t);

        bool operator==(texture const &) const;
        bool operator!=(texture const &) const;

        uint_size point_size() const;
        uint_size actual_size() const;
        double scale_factor() const;
        uint32_t depth() const;
        bool has_alpha() const;

        draw_image_result add_image(image const &image);
        draw_image_result replace_image(image const &image, uint_point const actual_origin);

        ui::metal_texture &metal_texture();

       protected:
        texture(std::shared_ptr<impl> &&);
    };

    using make_texture_result = result<ui::texture, setup_metal_error>;

    make_texture_result make_texture(texture::args);
}

std::string to_string(ui::texture::draw_image_error const);
}

std::ostream &operator<<(std::ostream &, yas::ui::texture::draw_image_error const &);
