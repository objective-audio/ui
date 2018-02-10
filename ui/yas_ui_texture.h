//
//  yas_ui_texture.h
//

#pragma once

#include "yas_base.h"
#include "yas_result.h"
#include "yas_ui_texture_protocol.h"
#include "yas_ui_metal_protocol.h"
#include "yas_ui_metal_system.h"
#include "yas_ui_types.h"

namespace yas::ui {
class image;
class metal_texture;

class texture : public base {
   public:
    class impl;

    struct args {
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
    using image_handler = std::function<void(ui::image &image, ui::uint_region const &tex_coords)>;

    explicit texture(args);
    texture(std::nullptr_t);

    bool operator==(texture const &) const;
    bool operator!=(texture const &) const;

    uint_size point_size() const;
    uint_size actual_size() const;
    double scale_factor() const;
    uint32_t depth() const;
    bool has_alpha() const;

    void add_image_handler(ui::uint_size, image_handler);

    ui::metal_texture &metal_texture();
    ui::metal_texture const &metal_texture() const;

    ui::renderable_texture &renderable();

    ui::metal_object &metal();

   private:
    ui::renderable_texture _renderable = nullptr;
    ui::metal_object _metal_object = nullptr;
};
}

namespace yas {
std::string to_string(ui::texture::draw_image_error const);
}

std::ostream &operator<<(std::ostream &, yas::ui::texture::draw_image_error const &);
