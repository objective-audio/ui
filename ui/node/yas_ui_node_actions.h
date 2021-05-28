//
//  yas_ui_node_actions.h
//

#pragma once

#include <ui/yas_ui_action.h>
#include <ui/yas_ui_angle.h>
#include <ui/yas_ui_color.h>
#include <ui/yas_ui_node.h>

namespace yas::ui {
struct translate_action_args final {
    node_wptr target;
    ui::point begin_position = {.v = 0.0f};
    ui::point end_position = {.v = 0.0f};

    double duration = 0.3;
    std::size_t loop_count = 1;
    transform_f value_transformer;

    time_point_t begin_time = std::chrono::system_clock::now();
    double delay = 0.0;
    action_completion_f completion;
};

struct rotate_action_args final {
    node_wptr target;
    ui::angle begin_angle = {0.0f};
    ui::angle end_angle = {0.0f};
    bool is_shortest = false;

    double duration = 0.3;
    std::size_t loop_count = 1;
    transform_f value_transformer;

    time_point_t begin_time = std::chrono::system_clock::now();
    double delay = 0.0;
    action_completion_f completion;
};

struct scale_action_args final {
    node_wptr target;
    ui::size begin_scale = {.v = 1.0f};
    ui::size end_scale = {.v = 1.0f};

    double duration = 0.3;
    std::size_t loop_count = 1;
    transform_f value_transformer;

    time_point_t begin_time = std::chrono::system_clock::now();
    double delay = 0.0;
    action_completion_f completion;
};

struct color_action_args final {
    node_wptr target;
    ui::color begin_color = {.v = 1.0f};
    ui::color end_color = {.v = 1.0f};

    double duration = 0.3;
    std::size_t loop_count = 1;
    transform_f value_transformer;

    time_point_t begin_time = std::chrono::system_clock::now();
    double delay = 0.0;
    action_completion_f completion;
};

struct alpha_action_args final {
    node_wptr target;
    float begin_alpha = 1.0f;
    float end_alpha = 1.0f;

    double duration = 0.3;
    std::size_t loop_count = 1;
    transform_f value_transformer;

    time_point_t begin_time = std::chrono::system_clock::now();
    double delay = 0.0;
    action_completion_f completion;
};

[[nodiscard]] std::shared_ptr<action> make_action(translate_action_args);
[[nodiscard]] std::shared_ptr<action> make_action(rotate_action_args);
[[nodiscard]] std::shared_ptr<action> make_action(scale_action_args);
[[nodiscard]] std::shared_ptr<action> make_action(color_action_args);
[[nodiscard]] std::shared_ptr<action> make_action(alpha_action_args);
}  // namespace yas::ui
