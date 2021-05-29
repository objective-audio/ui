//
//  yas_ui_action.h
//

#pragma once

#include <ui/yas_ui_action_dependency.h>
#include <ui/yas_ui_action_types.h>

namespace yas::ui {
struct action final {
    [[nodiscard]] std::shared_ptr<action_target> target() const;
    [[nodiscard]] time_point_t const &begin_time() const;
    [[nodiscard]] double delay() const;
    [[nodiscard]] action_time_update_f const &time_updater() const;
    [[nodiscard]] action_completion_f const &completion() const;

    bool update(time_point_t const &time);

    [[nodiscard]] static std::shared_ptr<action> make_shared();
    [[nodiscard]] static std::shared_ptr<action> make_shared(action_args &&);
    [[nodiscard]] static std::shared_ptr<action> make_continuous(continuous_action_args &&);
    [[nodiscard]] static std::shared_ptr<action> make_sequence(sequence_action_args &&);

   private:
    std::weak_ptr<action_target> _target;
    time_point_t _begin_time = std::chrono::system_clock::now();
    duration_t _delay{0.0};
    action_time_update_f _time_updater;
    action_completion_f _completion;

    explicit action(action_args &&);

    [[nodiscard]] duration_t time_diff(time_point_t const &time) const;
    [[nodiscard]] std::shared_ptr<action> make_delayed(time_point_t const &, double const) const;

    action(action const &) = delete;
    action(action &&) = delete;
    action &operator=(action const &) = delete;
    action &operator=(action &&) = delete;
};

struct parallel_action final {
    std::shared_ptr<action> const &raw_action() const;

    [[nodiscard]] std::vector<std::shared_ptr<action>> actions() const;
    [[nodiscard]] std::size_t action_count() const;

    void insert_action(std::shared_ptr<action>);
    void erase_action(std::shared_ptr<action> const &);

    [[nodiscard]] static std::shared_ptr<parallel_action> make_shared(parallel_action_args &&);

   private:
    std::shared_ptr<std::unordered_set<std::shared_ptr<action>>> _actions;
    std::shared_ptr<action> _raw_action;

    explicit parallel_action(parallel_action_args &&);

    parallel_action(parallel_action const &) = delete;
    parallel_action(parallel_action &&) = delete;
    parallel_action &operator=(parallel_action const &) = delete;
    parallel_action &operator=(parallel_action &&) = delete;
};
}  // namespace yas::ui
