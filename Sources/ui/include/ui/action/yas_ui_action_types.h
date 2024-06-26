//
//  yas_ui_action_types.h
//

#pragma once

#include <ui/action/yas_ui_action_group.h>
#include <ui/common/yas_ui_types.h>
#include <ui/utils/yas_ui_transformer.h>

#include <chrono>
#include <unordered_set>

namespace yas::ui {
using time_point_t = std::chrono::time_point<std::chrono::system_clock>;
using duration_t = std::chrono::duration<double>;
using action_completion_f = std::function<void(void)>;
using action_time_update_f = std::function<bool(time_point_t const &, action const &)>;
using continuous_value_update_f = std::function<void(double const)>;

struct action_args final {
    std::shared_ptr<action_group> group = nullptr;
    time_point_t begin_time = std::chrono::system_clock::now();
    double delay = 0.0;
    action_time_update_f time_updater;
    action_completion_f completion;
};

struct continuous_action_args final {
    double duration = 0.3;
    std::size_t loop_count = 1;
    continuous_value_update_f value_updater;
    transform_f value_transformer;

    std::shared_ptr<action_group> group = nullptr;
    time_point_t begin_time = std::chrono::system_clock::now();
    double delay = 0.0;
    action_completion_f completion;
};

struct sequence_action_args final {
    struct element final {
        std::shared_ptr<action> action;
        double duration = 0.0;
    };

    std::vector<element> elements;

    std::shared_ptr<action_group> group = nullptr;
    time_point_t begin_time = std::chrono::system_clock::now();
    double delay = 0.0;
    action_completion_f completion;
};

struct parallel_action_args final {
    std::unordered_set<std::shared_ptr<action>> actions;

    std::shared_ptr<action_group> group = nullptr;
    time_point_t begin_time = std::chrono::system_clock::now();
    double delay = 0.0;
    action_completion_f completion;
};
}  // namespace yas::ui
