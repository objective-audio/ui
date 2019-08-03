//
//  yas_ui_strings.h
//

#pragma once

#include "yas_ui_font_atlas.h"
#include "yas_ui_layout_types.h"

namespace yas::ui {
class font_atlas;
class rect_plane;
class layout_guide_rect;
enum class layout_alignment;

struct strings : base {
    class impl;

    struct args {
        std::size_t max_word_count = 16;
        std::string text;
        ui::font_atlas font_atlas = nullptr;
        std::optional<float> line_height = std::nullopt;
        ui::layout_alignment alignment = ui::layout_alignment::min;
        ui::region frame = ui::region::zero();
    };

    strings();
    explicit strings(args);
    strings(std::nullptr_t);

    virtual ~strings() final;

    void set_text(std::string);
    void set_font_atlas(ui::font_atlas);
    void set_line_height(std::optional<float>);
    void set_alignment(ui::layout_alignment const);

    std::string const &text() const;
    ui::font_atlas const &font_atlas() const;
    std::optional<float> const &line_height() const;
    ui::layout_alignment const &alignment() const;

    ui::layout_guide_rect &frame_layout_guide_rect();

    ui::rect_plane &rect_plane();

    [[nodiscard]] chaining::chain_sync_t<std::string> chain_text() const;
    [[nodiscard]] chaining::chain_sync_t<ui::font_atlas> chain_font_atlas() const;
    [[nodiscard]] chaining::chain_sync_t<std::optional<float>> chain_line_height() const;
    [[nodiscard]] chaining::chain_sync_t<ui::layout_alignment> chain_alignment() const;
    chaining::receiver<std::string> &text_receiver();
};
}  // namespace yas::ui
