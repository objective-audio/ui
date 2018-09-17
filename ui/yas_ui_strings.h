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

class strings : public base {
   public:
    class impl;

    struct args {
        std::size_t max_word_count = 16;
        std::string text;
        ui::font_atlas font_atlas = nullptr;
        std::experimental::optional<float> line_height = nullopt;
        ui::layout_alignment alignment = ui::layout_alignment::min;
        ui::region frame = ui::region::zero();
    };

    strings();
    explicit strings(args);
    strings(std::nullptr_t);

    virtual ~strings() final;

    void set_text(std::string);
    void set_font_atlas(ui::font_atlas);
    void set_line_height(opt_t<float>);
    void set_alignment(ui::layout_alignment const);

    std::string const &text() const;
    ui::font_atlas const &font_atlas() const;
    std::experimental::optional<float> const &line_height() const;
    ui::layout_alignment const &alignment() const;

    ui::layout_guide_rect &frame_layout_guide_rect();

    ui::rect_plane &rect_plane();

    [[nodiscard]] chaining::chain<std::string, std::string, std::string, true> chain_text() const;
    [[nodiscard]] chaining::chain<ui::font_atlas, ui::font_atlas, ui::font_atlas, true> chain_font_atlas() const;
    [[nodiscard]] chaining::chain<opt_t<float>, opt_t<float>, opt_t<float>, true> chain_line_height() const;
    [[nodiscard]] chaining::chain<ui::layout_alignment, ui::layout_alignment, ui::layout_alignment, true>
    chain_alignment() const;
    chaining::receiver<std::string> &text_receiver();
};
}  // namespace yas::ui
