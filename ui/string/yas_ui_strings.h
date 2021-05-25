//
//  yas_ui_strings.h
//

#pragma once

#include <ui/yas_ui_font_atlas.h>
#include <ui/yas_ui_layout_guide.h>
#include <ui/yas_ui_layout_types.h>
#include <ui/yas_ui_ptr.h>
#include <ui/yas_ui_rect_plane.h>
#include <ui/yas_ui_strings_types.h>

namespace yas::ui {
enum class layout_alignment;

struct strings final {
    virtual ~strings();

    void set_text(std::string);
    void set_font_atlas(ui::font_atlas_ptr);
    void set_line_height(std::optional<float>);
    void set_alignment(ui::layout_alignment const);

    [[nodiscard]] std::string const &text() const;
    [[nodiscard]] ui::font_atlas_ptr const &font_atlas() const;
    [[nodiscard]] std::optional<float> const &line_height() const;
    [[nodiscard]] ui::layout_alignment const &alignment() const;
    [[nodiscard]] std::optional<region> const &actual_frame() const;

    [[nodiscard]] ui::layout_guide_rect_ptr const &frame_layout_guide_rect();

    [[nodiscard]] ui::rect_plane_ptr const &rect_plane();

    [[nodiscard]] observing::syncable observe_text(observing::caller<std::string>::handler_f &&);
    [[nodiscard]] observing::syncable observe_font_atlas(observing::caller<ui::font_atlas_ptr>::handler_f &&);
    [[nodiscard]] observing::syncable observe_line_height(observing::caller<std::optional<float>>::handler_f &&);
    [[nodiscard]] observing::syncable observe_alignment(observing::caller<ui::layout_alignment>::handler_f &&);
    [[nodiscard]] observing::syncable observe_actual_frame(observing::caller<std::optional<region>>::handler_f &&);

    [[nodiscard]] static strings_ptr make_shared();
    [[nodiscard]] static strings_ptr make_shared(strings_args &&);

   private:
    std::shared_ptr<ui::collection_layout> const _collection_layout;
    ui::rect_plane_ptr const _rect_plane;

    observing::value::holder_ptr<std::string> const _text;
    observing::value::holder_ptr<ui::font_atlas_ptr> const _font_atlas;
    observing::value::holder_ptr<std::optional<float>> const _line_height;

    std::size_t const _max_word_count = 0;
    observing::canceller_pool _texture_pool;
    observing::canceller_pool _property_pool;
    observing::canceller_pool _cell_rect_pool;

    explicit strings(strings_args &&);

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
