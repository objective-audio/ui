//
//  yas_ui_strings.h
//

#pragma once

#include <ui/yas_ui_font_atlas.h>
#include <ui/yas_ui_layout_guide.h>
#include <ui/yas_ui_layout_types.h>
#include <ui/yas_ui_ptr.h>
#include <ui/yas_ui_rect_plane.h>

namespace yas::ui {
enum class layout_alignment;

struct strings final {
    struct args {
        std::size_t max_word_count = 16;
        std::string text;
        ui::font_atlas_ptr font_atlas = nullptr;
        std::optional<float> line_height = std::nullopt;
        ui::layout_alignment alignment = ui::layout_alignment::min;
        ui::region frame = ui::region::zero();
    };

    virtual ~strings();

    void set_text(std::string);
    void set_font_atlas(ui::font_atlas_ptr);
    void set_line_height(std::optional<float>);
    void set_alignment(ui::layout_alignment const);

    std::string const &text() const;
    ui::font_atlas_ptr const &font_atlas() const;
    std::optional<float> const &line_height() const;
    ui::layout_alignment const &alignment() const;

    ui::layout_guide_rect_ptr &frame_layout_guide_rect();

    ui::rect_plane_ptr const &rect_plane();

    [[nodiscard]] chaining::chain_sync_t<std::string> chain_text() const;
    [[nodiscard]] chaining::chain_sync_t<ui::font_atlas_ptr> chain_font_atlas() const;
    [[nodiscard]] chaining::chain_sync_t<std::optional<float>> chain_line_height() const;
    [[nodiscard]] chaining::chain_sync_t<ui::layout_alignment> chain_alignment() const;
    [[nodiscard]] chaining::receiver_ptr<std::string> text_receiver();

    [[nodiscard]] static strings_ptr make_shared();
    [[nodiscard]] static strings_ptr make_shared(args);

   private:
    std::shared_ptr<ui::collection_layout> _collection_layout;
    ui::rect_plane_ptr _rect_plane;
    chaining::perform_receiver_ptr<std::string> _text_receiver = nullptr;

    chaining::value::holder_ptr<std::string> _text;
    chaining::value::holder_ptr<ui::font_atlas_ptr> _font_atlas;
    chaining::value::holder_ptr<std::optional<float>> _line_height;

    ui::strings_wptr _weak_strings;
    std::size_t const _max_word_count = 0;
    chaining::perform_receiver_ptr<ui::texture_ptr> _texture_receiver = nullptr;
    chaining::perform_receiver_ptr<ui::font_atlas_ptr> _update_texture_receiver = nullptr;
    chaining::perform_receiver_ptr<std::nullptr_t> _update_layout_receiver = nullptr;
    std::optional<observing::canceller_ptr> _texture_canceller = std::nullopt;
    std::optional<observing::canceller_ptr> _texture_updated_canceller = std::nullopt;
    std::vector<chaining::any_observer_ptr> _property_observers;
    std::vector<chaining::any_observer_ptr> _cell_rect_observers;

    explicit strings(args);

    strings(strings const &) = delete;
    strings(strings &&) = delete;
    strings &operator=(strings const &) = delete;
    strings &operator=(strings &&) = delete;

    void _prepare(strings_ptr const &);
    void _prepare_receivers(ui::strings_wptr const &);
    void _prepare_chains(ui::strings_wptr const &);
    void _update_texture_chaining();
    void _update_layout();
    float _cell_height();
};
}  // namespace yas::ui
