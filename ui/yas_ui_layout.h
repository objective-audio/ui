//
//  yas_ui_layout.h
//

#pragma once

#include "yas_base.h"
#include "yas_ui_layout_guide.h"

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
[[nodiscard]] flow::observer make_flow(justified_layout::args);

[[nodiscard]] flow::observer make_flow(min_layout::args);
[[nodiscard]] flow::observer make_flow(max_layout::args);
}  // namespace yas::ui
