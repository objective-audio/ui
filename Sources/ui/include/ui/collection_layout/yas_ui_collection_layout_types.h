//
//  yas_ui_collection_layout_types.h
//

#pragma once

#include <ui/common/yas_ui_types.h>
#include <ui/layout/yas_ui_layout_types.h>

#include <vector>

namespace yas::ui {
struct collection_layout_line final {
    std::vector<ui::size> cell_sizes;
    float new_line_min_offset = 0.0f;

    bool operator==(collection_layout_line const &rhs) const;
    bool operator!=(collection_layout_line const &rhs) const;
};

struct collection_layout_args final {
    ui::region frame = ui::region::zero();
    std::size_t preferred_cell_count = 0;
    ui::size default_cell_size = {1.0f, 1.0f};
    std::vector<collection_layout_line> lines;
    float row_spacing = 0.0f;
    float col_spacing = 0.0f;
    ui::layout_borders borders;
    ui::layout_alignment alignment = ui::layout_alignment::min;
    ui::layout_direction direction = ui::layout_direction::vertical;
    ui::layout_order row_order = ui::layout_order::ascending;
    ui::layout_order col_order = ui::layout_order::ascending;
};
}  // namespace yas::ui
