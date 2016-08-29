//
//  yas_ui_justified_layout.h
//

#pragma once

#include "yas_ui_layout_guide.h"

namespace yas {
namespace ui {
    class layout;

    struct jusitified_layout_args {
        ui::layout_guide first_source_guide = nullptr;
        ui::layout_guide second_source_guide = nullptr;
        std::vector<ui::layout_guide> destination_guides;
        std::vector<float> ratios;
    };

    ui::layout make_justified_layout(jusitified_layout_args);
}
}
