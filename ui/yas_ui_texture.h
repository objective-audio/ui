//
//  yas_ui_texture.h
//

#pragma once

#include "yas_base.h"
#include "yas_result.h"
#include "yas_ui_metal_protocol.h"
#include "yas_ui_metal_system.h"
#include "yas_ui_types.h"
#include "yas_observing.h"

namespace yas::ui {
class image;
class metal_texture;

using image_handler = std::function<void(ui::image &image)>;
using image_pair_t = std::pair<uint_size, image_handler>;

class texture_element : public base {
   public:
    class impl;

    enum class method { tex_coords_changed };

    using subject_t = subject<method, texture_element>;
    using observer_t = subject_t::observer_t;

    texture_element(image_pair_t &&);
    texture_element(std::nullptr_t);

    image_pair_t const &image_pair() const;

    void set_tex_coords(ui::uint_region const &);
    ui::uint_region const &tex_coords() const;

    subject_t &subject();
};

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

    enum class method {
        metal_texture_changed,
        size_updated,
    };

    using subject_t = subject<method, ui::texture>;
    using observer_t = subject_t::observer_t;

    explicit texture(args);
    texture(std::nullptr_t);

    bool operator==(texture const &) const;
    bool operator!=(texture const &) const;

    uint_size point_size() const;
    uint_size actual_size() const;
    double scale_factor() const;
    uint32_t depth() const;
    bool has_alpha() const;

    void set_point_size(ui::uint_size);
    void set_scale_factor(double const);

    [[nodiscard]] texture_element const &add_image_handler(ui::uint_size, image_handler);
    void remove_image_handler(texture_element const &);

    ui::metal_texture &metal_texture();
    ui::metal_texture const &metal_texture() const;

    subject_t &subject();

    ui::metal_object &metal();

    void observe_scale_from_renderer(ui::renderer &);

   private:
    ui::metal_object _metal_object = nullptr;
};
}

namespace yas {
std::string to_string(ui::texture::method const &);
}

std::ostream &operator<<(std::ostream &, yas::ui::texture::method const &);
