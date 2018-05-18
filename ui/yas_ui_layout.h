//
//  yas_ui_layout.h
//

#pragma once

#include "yas_base.h"
#include "yas_ui_layout_guide.h"

namespace yas::ui::fixed_layout {
struct args {
    float distance;
    ui::layout_guide source_guide;
    ui::layout_guide destination_guide;
};
}  // namespace yas::ui::fixed_layout

namespace yas::ui::fixed_layout_point {
struct args {
    ui::point distances;
    ui::layout_guide_point source_guide_point;
    ui::layout_guide_point destination_guide_point;
};
}  // namespace yas::ui::fixed_layout_point

namespace yas::ui::fixed_layout_rect {
struct args {
    ui::insets distances;
    ui::layout_guide_rect source_guide_rect;
    ui::layout_guide_rect destination_guide_rect;
};
}  // namespace yas::ui::fixed_layout_rect

namespace yas::ui::justified_layout {
struct args {
    ui::layout_guide first_source_guide = nullptr;
    ui::layout_guide second_source_guide = nullptr;
    std::vector<ui::layout_guide> destination_guides;
    std::vector<float> ratios;
};
}  // namespace yas::ui::justified_layout

namespace yas::ui::min_layout {
struct args {
    std::vector<ui::layout_guide> source_guides;
    ui::layout_guide destination_guide;
};
}  // namespace yas::ui::min_layout

namespace yas::ui::max_layout {
struct args {
    std::vector<ui::layout_guide> source_guides;
    ui::layout_guide destination_guide;
};
}  // namespace yas::ui::max_layout

namespace yas::ui {
[[nodiscard]] flow::observer make_flow(fixed_layout::args);
[[nodiscard]] flow::observer make_flow(fixed_layout_point::args);
[[nodiscard]] flow::observer make_flow(fixed_layout_rect::args);

[[nodiscard]] flow::observer make_flow(justified_layout::args);

[[nodiscard]] flow::observer make_flow(min_layout::args);
[[nodiscard]] flow::observer make_flow(max_layout::args);
}  // namespace yas::ui
