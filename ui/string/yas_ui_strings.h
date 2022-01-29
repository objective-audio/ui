//
//  yas_ui_strings.h
//

#pragma once

#include <ui/yas_ui_font_atlas.h>
#include <ui/yas_ui_layout_guide.h>
#include <ui/yas_ui_layout_types.h>
#include <ui/yas_ui_rect_plane.h>
#include <ui/yas_ui_strings_types.h>

namespace yas::ui {
struct strings final {
    void set_text(std::string);
    void set_attributes(std::vector<strings_attribute> &&);
    void set_line_height(std::optional<float>);
    void set_alignment(ui::layout_alignment const);

    [[nodiscard]] std::string const &text() const;
    [[nodiscard]] std::vector<strings_attribute> const &attributes() const;
    [[nodiscard]] std::shared_ptr<ui::font_atlas> const &font_atlas() const;
    [[nodiscard]] std::optional<float> const &line_height() const;
    [[nodiscard]] ui::layout_alignment const &alignment() const;
    [[nodiscard]] region actual_frame() const;
    [[nodiscard]] std::vector<region> const &actual_cell_regions() const;

    [[nodiscard]] std::shared_ptr<layout_region_guide> const &preferred_layout_guide() const;
    [[nodiscard]] std::shared_ptr<layout_region_source> actual_layout_source() const;

    [[nodiscard]] std::shared_ptr<rect_plane> const &rect_plane();

    [[nodiscard]] observing::syncable observe_text(observing::caller<std::string>::handler_f &&);
    [[nodiscard]] observing::syncable observe_attributes(
        std::function<void(std::vector<strings_attribute> const &)> &&);
    [[nodiscard]] observing::syncable observe_line_height(observing::caller<std::optional<float>>::handler_f &&);
    [[nodiscard]] observing::syncable observe_alignment(observing::caller<ui::layout_alignment>::handler_f &&);
    [[nodiscard]] observing::syncable observe_actual_cell_regions(std::function<void(std::vector<region> const &)> &&);

    [[nodiscard]] static std::shared_ptr<strings> make_shared(strings_args &&, std::shared_ptr<ui::font_atlas> const &);

   private:
    std::shared_ptr<ui::collection_layout> const _collection_layout;
    std::string _collection_text;
    std::shared_ptr<ui::rect_plane> const _rect_plane;

    observing::value::holder_ptr<std::string> const _text;
    observing::value::holder_ptr<std::vector<strings_attribute>> const _attributes;
    std::shared_ptr<ui::font_atlas> const _font_atlas;
    observing::value::holder_ptr<std::optional<float>> const _line_height;

    std::size_t const _max_word_count = 0;
    observing::canceller_pool _pool;

    explicit strings(strings_args &&, std::shared_ptr<ui::font_atlas> const &);

    strings(strings const &) = delete;
    strings(strings &&) = delete;
    strings &operator=(strings const &) = delete;
    strings &operator=(strings &&) = delete;

    void _prepare_observings();
    void _update_collection_layout();
    void _update_data_rects();
    void _update_data_rect_colors();
    simd::float4 _rect_color_at(std::size_t const) const;
    float _cell_height();
};
}  // namespace yas::ui
