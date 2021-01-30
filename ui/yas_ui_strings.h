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

    ui::layout_guide_rect_ptr const &frame_layout_guide_rect();

    ui::rect_plane_ptr const &rect_plane();

    [[nodiscard]] observing::canceller_ptr observe_text(observing::caller<std::string>::handler_f &&, bool const sync);
    [[nodiscard]] observing::canceller_ptr observe_font_atlas(observing::caller<ui::font_atlas_ptr>::handler_f &&,
                                                              bool const sync);
    [[nodiscard]] observing::canceller_ptr observe_line_height(observing::caller<std::optional<float>>::handler_f &&,
                                                               bool const sync);
    [[nodiscard]] observing::canceller_ptr observe_alignment(observing::caller<ui::layout_alignment>::handler_f &&,
                                                             bool const sync);

    [[nodiscard]] static strings_ptr make_shared();
    [[nodiscard]] static strings_ptr make_shared(args);

   private:
    std::shared_ptr<ui::collection_layout> _collection_layout;
    ui::rect_plane_ptr _rect_plane;

    observing::value::holder_ptr<std::string> _text;
    observing::value::holder_ptr<ui::font_atlas_ptr> _font_atlas;
    observing::value::holder_ptr<std::optional<float>> _line_height;

    std::size_t const _max_word_count = 0;
    observing::canceller_pool _texture_pool;
    observing::canceller_pool_ptr const _property_pool = observing::canceller_pool::make_shared();
    observing::canceller_pool _cell_rect_pool;

    explicit strings(args);

    strings(strings const &) = delete;
    strings(strings &&) = delete;
    strings &operator=(strings const &) = delete;
    strings &operator=(strings &&) = delete;

    void _prepare_chains();
    void _update_texture_observing();
    void _update_layout();
    float _cell_height();
};
}  // namespace yas::ui
