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
    action_target_wptr target;
    time_point_t begin_time = std::chrono::system_clock::now();
    double delay = 0.0;
};

struct continuous_action_args final {
    double duration = 0.3;
    std::size_t loop_count = 1;
};

struct parallel_action_args final {
    std::unordered_set<action_ptr> actions;
};

struct continuous_action final {
    using value_update_f = std::function<void(double const)>;

    double duration() const;
    value_update_f const &value_updater() const;
    transform_f const &value_transformer() const;
    std::size_t loop_count() const;

    void set_value_updater(value_update_f);
    void set_value_transformer(transform_f);

    [[nodiscard]] static continuous_action_ptr make_shared(continuous_action_args);

   private:
    double _duration = 0.3;
    value_update_f _value_updater;
    transform_f _value_transformer;
    std::size_t _loop_count = 1;
    std::size_t _index = 0;

    explicit continuous_action(continuous_action_args &&args);
};

struct parallel_action final {
    std::vector<action_ptr> actions() const;
    std::size_t action_count() const;

    void insert_action(action_ptr);
    void erase_action(action_ptr const &);

    [[nodiscard]] static parallel_action_ptr make_shared(std::unordered_set<action_ptr> &&);

   private:
    std::unordered_set<action_ptr> _actions;

    explicit parallel_action(std::unordered_set<action_ptr> &&);
};

struct action final {
    using time_update_f = std::function<bool(time_point_t const &)>;
    using completion_f = std::function<void(void)>;

    virtual ~action() = default;

    [[nodiscard]] action_target_ptr target() const;
    [[nodiscard]] time_point_t const &begin_time() const;
    [[nodiscard]] double delay() const;
    [[nodiscard]] time_update_f const &time_updater() const;
    [[nodiscard]] completion_f const &completion_handler() const;

    void set_target(action_target_wptr const &);
    void set_time_updater(time_update_f);
    void set_completion_handler(completion_f);

    bool update(time_point_t const &time);

    bool is_continous() const;
    bool is_parallel() const;
    continuous_action_ptr const &continuous() const;
    parallel_action_ptr const &parallel() const;

    [[nodiscard]] static action_ptr make_shared();
    [[nodiscard]] static action_ptr make_shared(action_args);

    [[nodiscard]] static action_ptr make_continuous();
    [[nodiscard]] static action_ptr make_continuous(action_args, continuous_action_args);

    [[nodiscard]] static action_ptr make_parallel();
    [[nodiscard]] static action_ptr make_parallel(action_args, parallel_action_args);

    [[nodiscard]] static action_ptr make_sequence(std::vector<action_ptr> actions, time_point_t const &begin_time);

   protected:
    continuous_action_ptr _continuous;
    parallel_action_ptr _parallel;
    action_target_wptr _target;
    time_point_t _begin_time = std::chrono::system_clock::now();
    duration_t _delay{0.0};
    time_update_f _time_updater;
    completion_f _completion_handler;

    explicit action(action_args);

    action(action const &) = delete;
    action(action &&) = delete;
    action &operator=(action const &) = delete;
    action &operator=(action &&) = delete;

    duration_t time_diff(time_point_t const &time);
};
}  // namespace yas::ui
