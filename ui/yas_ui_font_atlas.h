//
//  yas_ui_font.h
//

#pragma once

#include "yas_ui_texture.h"
#include "yas_ui_types.h"

namespace yas::ui {
class font_atlas : public base {
   public:
    class impl;

    enum class method { texture_changed, texture_updated };

    struct args {
        std::string font_name;
        double font_size;
        std::string words;
        ui::texture texture = nullptr;
    };

    font_atlas(args);
    font_atlas(std::nullptr_t);

    virtual ~font_atlas() final;

    std::string const &font_name() const;
    double const &font_size() const;
    double const &ascent() const;
    double const &descent() const;
    double const &leading() const;
    std::string const &words() const;
    ui::texture const &texture() const;

    ui::vertex2d_rect_t const &rect(std::string const &word) const;
    ui::size advance(std::string const &word) const;

    void set_texture(ui::texture);

    [[nodiscard]] chaining::chain<ui::texture, ui::texture, ui::texture, true> chain_texture() const;
    [[nodiscard]] chaining::chain<ui::texture, ui::texture, ui::texture, false> chain_texture_updated() const;
};
}  // namespace yas::ui

namespace yas {
std::string to_string(ui::font_atlas::method const &);
}
