//
//  yas_ui_strings.h
//

#pragma once

#include "yas_ui_font_atlas.h"
#include "yas_ui_layout_guide.h"
#include "yas_ui_layout_types.h"
#include "yas_ui_ptr.h"
#include "yas_ui_rect_plane.h"

namespace yas::ui {
enum class layout_alignment;

struct strings final {
    class impl;

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
    std::unique_ptr<impl> _impl;

    explicit strings(args);

    void _prepare(strings_ptr const &);
};
}  // namespace yas::ui
