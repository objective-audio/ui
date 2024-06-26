//
//  yas_ui_font.h
//

#pragma once

#include <ui/common/yas_ui_types.h>
#include <ui/texture/yas_ui_texture.h>

#include "yas_ui_font_atlas_types.h"

namespace yas::ui {
class word_info;

struct font_atlas final {
    [[nodiscard]] std::string const &font_name() const;
    [[nodiscard]] double const &font_size() const;
    [[nodiscard]] double const &ascent() const;
    [[nodiscard]] double const &descent() const;
    [[nodiscard]] double const &leading() const;
    [[nodiscard]] std::string words() const;
    [[nodiscard]] std::shared_ptr<texture> const &texture() const;

    [[nodiscard]] ui::vertex2d_rect const &rect(std::string const &word) const;
    [[nodiscard]] ui::size advance(std::string const &word) const;

    [[nodiscard]] observing::endable observe_rects_updated(std::function<void(std::nullptr_t const &)> &&);
    [[nodiscard]] observing::endable observe_rects_updated(std::size_t const order,
                                                           std::function<void(std::nullptr_t const &)> &&);

    [[nodiscard]] static std::shared_ptr<font_atlas> make_shared(font_atlas_args &&,
                                                                 std::shared_ptr<ui::texture> const &);

   private:
    class impl;

    std::unique_ptr<impl> _impl;

    std::string const _font_name;
    double const _font_size;
    double const _ascent;
    double const _descent;
    double const _leading;
    observing::notifier_ptr<std::nullptr_t> const _rects_updated_notifier =
        observing::notifier<std::nullptr_t>::make_shared();

    std::shared_ptr<ui::texture> const _texture;
    std::map<std::string, ui::word_info> _word_infos;
    std::optional<observing::cancellable_ptr> _rects_canceller = std::nullopt;

    font_atlas(font_atlas_args &&, std::shared_ptr<ui::texture> const &);

    font_atlas(font_atlas const &) = delete;
    font_atlas(font_atlas &&) = delete;
    font_atlas &operator=(font_atlas const &) = delete;
    font_atlas &operator=(font_atlas &&) = delete;

    void _setup(std::string const &words);
    void _update_tex_coords();
};
}  // namespace yas::ui
