//
//  yas_ui_strings_types.h
//

#pragma once

namespace yas::ui {
struct strings_args final {
    std::size_t max_word_count = 16;
    std::string text;
    std::shared_ptr<ui::font_atlas> font_atlas = nullptr;
    std::optional<float> line_height = std::nullopt;
    ui::layout_alignment alignment = ui::layout_alignment::min;
    ui::region frame = ui::region::zero();
};
}  // namespace yas::ui
