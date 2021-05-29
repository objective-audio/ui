//
//  yas_ui_action.h
//

#pragma once

#include <ui/yas_ui_action_types.h>

namespace yas::ui {
struct action_target {
    virtual ~action_target() = default;
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
    action_ptr const &raw_action() const;

    [[nodiscard]] std::vector<action_ptr> actions() const;
    [[nodiscard]] std::size_t action_count() const;

    void insert_action(action_ptr);
    void erase_action(action_ptr const &);

    [[nodiscard]] static parallel_action_ptr make_shared(parallel_action_args &&);

   private:
    std::shared_ptr<std::unordered_set<action_ptr>> _actions;
    action_ptr _raw_action;

    explicit parallel_action(parallel_action_args &&);

    parallel_action(parallel_action const &) = delete;
    parallel_action(parallel_action &&) = delete;
    parallel_action &operator=(parallel_action const &) = delete;
    parallel_action &operator=(parallel_action &&) = delete;
};
}  // namespace yas::ui
