//
//  yas_ui_fixed_layout.h
//

#pragma once

#include "yas_base.h"
#include "yas_ui_layout_guide.h"

namespace yas {
namespace ui {
    class layout;

    struct fixed_layout_args {
        float distance;
        ui::layout_guide source_guide;
        ui::layout_guide destination_guide;
    };

    ui::layout make_fixed_layout(fixed_layout_args);
}
}
