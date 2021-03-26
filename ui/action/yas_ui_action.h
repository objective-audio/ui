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

struct action_target {
    virtual ~action_target() = default;
};

struct action_args final {
    time_point_t begin_time = std::chrono::system_clock::now();
    double delay = 0.0;
};

struct continuous_action_args final {
    double duration = 0.3;
    std::size_t loop_count = 1;
};

struct parallel_action_args final {
    action_target_wptr target;
    std::unordered_set<action_ptr> actions;
};

struct continuous_action final {
    using value_update_f = std::function<void(double const)>;

    value_update_f value_updater;
    transform_f value_transformer;

    [[nodiscard]] double duration() const;
    [[nodiscard]] std::size_t loop_count() const;

    [[nodiscard]] static continuous_action_ptr make_shared(continuous_action_args);

   private:
    double _duration = 0.3;
    std::size_t _loop_count = 1;

    explicit continuous_action(continuous_action_args &&args);
};

struct parallel_action final {
    [[nodiscard]] std::vector<action_ptr> actions() const;
    [[nodiscard]] std::size_t action_count() const;

    void insert_action(action_ptr);
    void erase_action(action_ptr const &);

    [[nodiscard]] static parallel_action_ptr make_shared(std::unordered_set<action_ptr> &&);

   private:
    std::unordered_set<action_ptr> _actions;

    explicit parallel_action(std::unordered_set<action_ptr> &&);
};

struct sequence_action final {
    action_ptr action;
    double duration = 0.0;
};

struct action final {
    using time_update_f = std::function<bool(time_point_t const &)>;
    using completion_f = std::function<void(void)>;

    time_update_f time_updater;
    completion_f completion_handler;

    [[nodiscard]] action_target_ptr target() const;
    [[nodiscard]] time_point_t const &begin_time() const;
    [[nodiscard]] double delay() const;

    void set_target(action_target_wptr const &);

    bool update(time_point_t const &time);

    [[nodiscard]] bool is_continous() const;
    [[nodiscard]] bool is_parallel() const;
    [[nodiscard]] continuous_action_ptr const &continuous() const;
    [[nodiscard]] parallel_action_ptr const &parallel() const;

    [[nodiscard]] static action_ptr make_shared();
    [[nodiscard]] static action_ptr make_shared(action_args);

    [[nodiscard]] static action_ptr make_continuous();
    [[nodiscard]] static action_ptr make_continuous(action_args, continuous_action_args);

    [[nodiscard]] static action_ptr make_parallel();
    [[nodiscard]] static action_ptr make_parallel(action_args, parallel_action_args);

    [[nodiscard]] static action_ptr make_sequence(std::vector<sequence_action> actions, time_point_t const &begin_time);

   private:
    continuous_action_ptr _continuous;
    parallel_action_ptr _parallel;
    action_target_wptr _target;
    time_point_t _begin_time = std::chrono::system_clock::now();
    duration_t _delay{0.0};

    explicit action(action_args);

    action(action const &) = delete;
    action(action &&) = delete;
    action &operator=(action const &) = delete;
    action &operator=(action &&) = delete;

    duration_t time_diff(time_point_t const &time);
};
}  // namespace yas::ui