//
//  yas_ui_layout_actions.h
//

#pragma once

#include "yas_ui_action.h"
#include "yas_ui_layout_guide.h"

namespace yas {
namespace ui {
    namespace layout_action {
        struct args {
            weak<ui::layout_guide> target;
            float start_value;
            float end_value;

            continuous_action::args continuous_action;
        };
    }

    namespace layout_point_action {
        struct args {
            weak<ui::layout_guide_point> target;
            ui::point start_point;
            ui::point end_point;

            continuous_action::args continuous_action;
        };
    }

    namespace layout_range_action {
        struct args {
            weak<ui::layout_guide_range> target;
            ui::range start_range;
            ui::range end_range;

            continuous_action::args continuous_action;
        };
    }

    namespace layout_rect_action {
        struct args {
            weak<ui::layout_guide_rect> target;
            ui::region start_region;
            ui::region end_region;

            continuous_action::args continuous_action;
        };
    }

    ui::continuous_action make_action(layout_action::args);
    ui::continuous_action make_action(layout_point_action::args);
    ui::continuous_action make_action(layout_range_action::args);
    ui::continuous_action make_action(layout_rect_action::args);
}
}
