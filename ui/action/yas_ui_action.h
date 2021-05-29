//
//  yas_ui_action.h
//

#pragma once

#include <ui/yas_ui_ptr.h>
#include <ui/yas_ui_transformer.h>
#include <ui/yas_ui_types.h>

#include <chrono>
#include <unordered_set>
#include <vector>

namespace yas::ui {
using time_point_t = std::chrono::time_point<std::chrono::system_clock>;
using duration_t = std::chrono::duration<double>;
using action_completion_f = std::function<void(void)>;
using action_time_update_f = std::function<bool(time_point_t const &, action const &)>;
using continuous_value_update_f = std::function<void(double const)>;

struct action_target {
    virtual ~action_target() = default;
};

struct action_args final {
    action_target_wptr target;
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

    action_target_wptr target;
    time_point_t begin_time = std::chrono::system_clock::now();
    double delay = 0.0;
    action_completion_f completion;
};

struct sequence_action_args final {
    struct element final {
        action_ptr action;
        double duration = 0.0;
    };

    std::vector<element> elements;

    action_target_wptr target;
    time_point_t begin_time = std::chrono::system_clock::now();
    double delay = 0.0;
    action_completion_f completion;
};

struct action final {
    [[nodiscard]] action_target_ptr target() const;
    [[nodiscard]] time_point_t const &begin_time() const;
    [[nodiscard]] double delay() const;
    [[nodiscard]] action_time_update_f const &time_updater() const;
    [[nodiscard]] action_completion_f const &completion() const;

    bool update(time_point_t const &time);

    [[nodiscard]] static action_ptr make_shared();
    [[nodiscard]] static action_ptr make_shared(action_args &&);
    [[nodiscard]] static action_ptr make_continuous(continuous_action_args &&);
    [[nodiscard]] static action_ptr make_sequence(sequence_action_args &&);

   private:
    action_target_wptr _target;
    time_point_t _begin_time = std::chrono::system_clock::now();
    duration_t _delay{0.0};
    action_time_update_f _time_updater;
    action_completion_f _completion;

    explicit action(action_args &&);

    [[nodiscard]] duration_t time_diff(time_point_t const &time) const;
    [[nodiscard]] action_ptr make_delayed(time_point_t const &, double const) const;

    action(action const &) = delete;
    action(action &&) = delete;
    action &operator=(action const &) = delete;
    action &operator=(action &&) = delete;
};

struct parallel_action final {
    struct args final {
        std::unordered_set<action_ptr> actions;

        action_target_wptr target;
        time_point_t begin_time = std::chrono::system_clock::now();
        double delay = 0.0;
        action_completion_f completion;
    };

    action_ptr const &raw_action() const;

    [[nodiscard]] std::vector<action_ptr> actions() const;
    [[nodiscard]] std::size_t action_count() const;

    void insert_action(action_ptr);
    void erase_action(action_ptr const &);

    [[nodiscard]] static parallel_action_ptr make_shared(args &&);

   private:
    std::shared_ptr<std::unordered_set<action_ptr>> _actions;
    action_ptr _raw_action;

    explicit parallel_action(args &&);

    parallel_action(parallel_action const &) = delete;
    parallel_action(parallel_action &&) = delete;
    parallel_action &operator=(parallel_action const &) = delete;
    parallel_action &operator=(parallel_action &&) = delete;
};
}  // namespace yas::ui
