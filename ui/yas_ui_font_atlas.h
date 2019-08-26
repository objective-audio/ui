//
//  yas_ui_font.h
//

#pragma once

#include "yas_ui_ptr.h"
#include "yas_ui_texture.h"
#include "yas_ui_types.h"

namespace yas::ui {

struct font_atlas final {
    class impl;

    enum class method { texture_changed, texture_updated };

    struct args {
        std::string font_name;
        double font_size;
        std::string words;
        ui::texture_ptr texture = nullptr;
    };

    virtual ~font_atlas();

    std::string const &font_name() const;
    double const &font_size() const;
    double const &ascent() const;
    double const &descent() const;
    double const &leading() const;
    std::string const &words() const;
    ui::texture_ptr const &texture() const;

    ui::vertex2d_rect_t const &rect(std::string const &word) const;
    ui::size advance(std::string const &word) const;

    void set_texture(ui::texture_ptr const &);

    [[nodiscard]] chaining::chain_sync_t<ui::texture_ptr> chain_texture() const;
    [[nodiscard]] chaining::chain_unsync_t<ui::texture_ptr> chain_texture_updated() const;

    [[nodiscard]] static font_atlas_ptr make_shared(args);

   private:
    std::unique_ptr<impl> _impl;

    font_atlas(args &&);

    font_atlas(font_atlas const &) = delete;
    font_atlas(font_atlas &&) = delete;
    font_atlas &operator=(font_atlas const &) = delete;
    font_atlas &operator=(font_atlas &&) = delete;

    void _prepare(font_atlas_ptr const &, ui::texture_ptr const &);
};
}  // namespace yas::ui

namespace yas {
std::string to_string(ui::font_atlas::method const &);
}
