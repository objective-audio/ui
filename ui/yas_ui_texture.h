//
//  yas_ui_texture.h
//

#pragma once

#include "yas_base.h"
#include "yas_chaining.h"
#include "yas_result.h"
#include "yas_ui_metal_protocol.h"
#include "yas_ui_metal_system.h"
#include "yas_ui_texture_protocol.h"
#include "yas_ui_types.h"

namespace yas::ui {
class image;
class metal_texture;
class texture_element;

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

    [[nodiscard]] texture_element const &add_draw_handler(ui::uint_size, ui::draw_handler_f);
    void remove_draw_handler(texture_element const &);

    ui::metal_texture &metal_texture();
    ui::metal_texture const &metal_texture() const;

    using chain_pair_t = std::pair<method, texture>;
    [[nodiscard]] chaining::chain<chain_pair_t, chain_pair_t, chain_pair_t, false> chain() const;
    [[nodiscard]] chaining::chain<texture, chain_pair_t, chain_pair_t, false> chain(method const &) const;
    chaining::receiver<double> &scale_factor_receiver();

    ui::metal_object &metal();

    void sync_scale_from_renderer(ui::renderer const &);

   private:
    ui::metal_object _metal_object = nullptr;
};
}  // namespace yas::ui

namespace yas {
std::string to_string(ui::texture::method const &);
}

std::ostream &operator<<(std::ostream &, yas::ui::texture::method const &);
