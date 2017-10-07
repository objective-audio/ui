//
//  yas_ui_node_actions.h
//

#pragma once

#include "yas_ui_action.h"
#include "yas_ui_node.h"
#include "yas_ui_color.h"

namespace yas {
namespace ui {
    namespace translate_action {
        struct args {
            weak<ui::node> target;
            ui::point start_position = {.v = 0.0f};
            ui::point end_position = {.v = 0.0f};

            continuous_action::args continuous_action;
        };
    }

    namespace rotate_action {
        struct args {
            weak<ui::node> target;
            float start_angle = 0.0f;
            float end_angle = 0.0f;
            bool is_shortest = false;

            continuous_action::args continuous_action;
        };
    }

    namespace scale_action {
        struct args {
            weak<ui::node> target;
            ui::size start_scale = {.v = 1.0f};
            ui::size end_scale = {.v = 1.0f};

            continuous_action::args continuous_action;
        };
    }

    namespace color_action {
        struct args {
            weak<ui::node> target;
            ui::color start_color = {.v = 1.0f};
            ui::color end_color = {.v = 1.0f};

            continuous_action::args continuous_action;
        };
    }

    namespace alpha_action {
        struct args {
            weak<ui::node> target;
            float start_alpha = 1.0f;
            float end_alpha = 1.0f;

            continuous_action::args continuous_action;
        };
    }

    continuous_action make_action(translate_action::args);
    continuous_action make_action(rotate_action::args);
    continuous_action make_action(scale_action::args);
    continuous_action make_action(color_action::args);
    continuous_action make_action(alpha_action::args);
}
}
