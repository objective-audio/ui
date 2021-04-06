//
//  yas_ui_node_actions.h
//

#pragma once

#include <ui/yas_ui_action.h>
#include <ui/yas_ui_angle.h>
#include <ui/yas_ui_color.h>
#include <ui/yas_ui_node.h>

namespace yas::ui {
namespace translate_action {
    struct args {
        node_wptr target;
        ui::point begin_position = {.v = 0.0f};
        ui::point end_position = {.v = 0.0f};

        action::continuous_args continuous_action;
    };
}  // namespace translate_action

namespace rotate_action {
    struct args {
        node_wptr target;
        ui::angle begin_angle = {0.0f};
        ui::angle end_angle = {0.0f};
        bool is_shortest = false;

        action::continuous_args continuous_action;
    };
}  // namespace rotate_action

namespace scale_action {
    struct args {
        node_wptr target;
        ui::size begin_scale = {.v = 1.0f};
        ui::size end_scale = {.v = 1.0f};

        action::continuous_args continuous_action;
    };
}  // namespace scale_action

namespace color_action {
    struct args {
        node_wptr target;
        ui::color begin_color = {.v = 1.0f};
        ui::color end_color = {.v = 1.0f};

        action::continuous_args continuous_action;
    };
}  // namespace color_action

namespace alpha_action {
    struct args {
        node_wptr target;
        float begin_alpha = 1.0f;
        float end_alpha = 1.0f;

        action::continuous_args continuous_action;
    };
}  // namespace alpha_action

[[nodiscard]] std::shared_ptr<action> make_action(translate_action::args);
[[nodiscard]] std::shared_ptr<action> make_action(rotate_action::args);
[[nodiscard]] std::shared_ptr<action> make_action(scale_action::args);
[[nodiscard]] std::shared_ptr<action> make_action(color_action::args);
[[nodiscard]] std::shared_ptr<action> make_action(alpha_action::args);
}  // namespace yas::ui
