//
//  yas_ui_font.h
//

#pragma once

#include <ui/yas_ui_ptr.h>
#include <ui/yas_ui_texture.h>
#include <ui/yas_ui_types.h>

namespace yas::ui {
class word_info;

struct font_atlas final {
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

    [[nodiscard]] observing::canceller_ptr observe_texture(observing::caller<texture_ptr>::handler_f &&,
                                                           bool const sync = true);
    [[nodiscard]] observing::canceller_ptr observe_texture_updated(observing::caller<texture_ptr>::handler_f &&);

    [[nodiscard]] static font_atlas_ptr make_shared(args);

   private:
    class impl;

    std::unique_ptr<impl> _impl;

    std::string _font_name;
    double _font_size;
    double _ascent;
    double _descent;
    double _leading;
    std::string _words;
    observing::fetcher_ptr<ui::texture_ptr> _texture_changed_fetcher = nullptr;
    observing::notifier_ptr<ui::texture_ptr> const _texture_updated_notifier =
        observing::notifier<ui::texture_ptr>::make_shared();

    observing::value::holder_ptr<ui::texture_ptr> const _texture =
        observing::value::holder<ui::texture_ptr>::make_shared(nullptr);
    std::vector<ui::word_info> _word_infos;
    chaining::perform_receiver_ptr<std::pair<ui::uint_region, std::size_t>> _word_tex_coords_receiver = nullptr;
    std::vector<chaining::any_observer_ptr> _element_observers;
    chaining::perform_receiver_ptr<ui::texture_ptr> _texture_updated_receiver = nullptr;
    std::optional<observing::canceller_ptr> _texture_canceller = std::nullopt;
    observing::canceller_ptr _texture_changed_canceller = nullptr;
    chaining::perform_receiver_ptr<ui::texture_ptr> _texture_changed_receiver = nullptr;

    font_atlas(args &&);

    font_atlas(font_atlas const &) = delete;
    font_atlas(font_atlas &&) = delete;
    font_atlas &operator=(font_atlas const &) = delete;
    font_atlas &operator=(font_atlas &&) = delete;

    void _prepare(ui::texture_ptr const &);
    void _update_word_infos();
};
}  // namespace yas::ui

namespace yas {
std::string to_string(ui::font_atlas::method const &);
}
