//
//  yas_ui_strings_types.h
//

#pragma once

#include <cpp-utils/index_range.h>
#include <ui/color/yas_ui_color.h>
#include <ui/common/yas_ui_types.h>
#include <ui/layout/yas_ui_layout_types.h>

#include <optional>
#include <vector>

namespace yas::ui {
struct strings_attribute {
    std::optional<index_range> range = std::nullopt;
    ui::color color = to_color(ui::white_color(), 1.0f);

    bool operator==(strings_attribute const &rhs) const;
    bool operator!=(strings_attribute const &rhs) const;
};

struct strings_args final {
    std::size_t max_word_count = 16;
    std::string text;
    std::vector<strings_attribute> attributes;
    std::optional<float> line_height = std::nullopt;
    ui::layout_alignment alignment = ui::layout_alignment::min;
    ui::region frame = ui::region::zero();
};
}  // namespace yas::ui
