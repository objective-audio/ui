//
//  yas_ui_font.h
//

#pragma once

#include <ui/yas_ui_font_atlas_types.h>
#include <ui/yas_ui_texture.h>
#include <ui/yas_ui_types.h>

namespace yas::ui {
class word_info;

struct font_atlas final {
    using args = font_atlas_args;

    virtual ~font_atlas();

    [[nodiscard]] std::string const &font_name() const;
    [[nodiscard]] double const &font_size() const;
    [[nodiscard]] double const &ascent() const;
    [[nodiscard]] double const &descent() const;
    [[nodiscard]] double const &leading() const;
    [[nodiscard]] std::string const &words() const;
    [[nodiscard]] ui::texture_ptr const &texture() const;

    [[nodiscard]] ui::vertex2d_rect_t const &rect(std::string const &word) const;
    [[nodiscard]] ui::size advance(std::string const &word) const;

    void set_texture(ui::texture_ptr const &);

    [[nodiscard]] observing::syncable observe_texture(observing::caller<texture_ptr>::handler_f &&);
    [[nodiscard]] observing::endable observe_texture_updated(observing::caller<ui::texture_ptr>::handler_f &&);

    [[nodiscard]] static font_atlas_ptr make_shared(args);

   private:
    class impl;

    std::unique_ptr<impl> _impl;

    std::string const _font_name;
    double const _font_size;
    double const _ascent;
    double const _descent;
    double const _leading;
    std::string const _words;
    observing::fetcher_ptr<ui::texture_ptr> _texture_changed_fetcher = nullptr;
    observing::notifier_ptr<ui::texture_ptr> const _texture_updated_notifier =
        observing::notifier<ui::texture_ptr>::make_shared();

    observing::value::holder_ptr<ui::texture_ptr> const _texture;
    std::vector<ui::word_info> _word_infos;
    std::vector<observing::cancellable_ptr> _element_cancellers;
    std::optional<observing::cancellable_ptr> _texture_canceller = std::nullopt;
    observing::cancellable_ptr _texture_changed_canceller = nullptr;

    font_atlas(args &&);

    font_atlas(font_atlas const &) = delete;
    font_atlas(font_atlas &&) = delete;
    font_atlas &operator=(font_atlas const &) = delete;
    font_atlas &operator=(font_atlas &&) = delete;

    void _update_word_infos();
};
}  // namespace yas::ui
