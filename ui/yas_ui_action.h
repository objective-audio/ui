//
//  yas_ui_action.h
//

#pragma once

#include <cpp_utils/yas_protocol.h>
#include <chrono>
#include <unordered_set>
#include <vector>
#include "yas_ui_ptr.h"
#include "yas_ui_transformer.h"
#include "yas_ui_types.h"

namespace yas::ui {
using time_point_t = std::chrono::time_point<std::chrono::system_clock>;
using duration_t = std::chrono::duration<double>;

struct action_target {
    virtual ~action_target() = default;
};

class updatable_action;
using updatable_action_ptr = std::shared_ptr<updatable_action>;

struct updatable_action {
    virtual ~updatable_action() = default;

    virtual bool update(time_point_t const &time) = 0;

    static updatable_action_ptr cast(updatable_action_ptr const &);
};

struct action : updatable_action {
    struct args {
        time_point_t begin_time = std::chrono::system_clock::now();
        double delay = 0.0;
    };

    using time_update_f = std::function<bool(time_point_t const &)>;
    using value_update_f = std::function<void(double const)>;
    using completion_f = std::function<void(void)>;

    action_target_ptr target() const;
    time_point_t const &begin_time() const;
    double delay() const;
    time_update_f const &time_updater() const;
    completion_f const &completion_handler() const;

    void set_target(action_target_wptr const &);
    void set_time_updater(time_update_f);
    void set_completion_handler(completion_f);

    [[nodiscard]] static action_ptr make_shared();
    [[nodiscard]] static action_ptr make_shared(args);

   protected:
    std::weak_ptr<action> _weak_action;
    action_target_wptr _target;
    time_point_t _begin_time = std::chrono::system_clock::now();
    duration_t _delay{0.0};
    time_update_f _time_updater;
    completion_f _completion_handler;

    explicit action(args);

    duration_t time_diff(time_point_t const &time);

   private:
    bool update(time_point_t const &time) override;

    friend ui::parallel_action_ptr make_action_sequence(std::vector<action_ptr>, time_point_t const &);
};
}  // namespace yas::ui

namespace yas::ui {

struct continuous_action final : action {
    struct args {
        double duration = 0.3;
        std::size_t loop_count = 1;

        action::args action;
    };

    virtual ~continuous_action();

    double duration() const;
    value_update_f const &value_updater() const;
    transform_f const &value_transformer() const;
    std::size_t loop_count() const;

    void set_value_updater(value_update_f);
    void set_value_transformer(transform_f);

    [[nodiscard]] static continuous_action_ptr make_shared();
    [[nodiscard]] static continuous_action_ptr make_shared(args);

   private:
    double _duration = 0.3;
    value_update_f _value_updater;
    transform_f _value_transformer;
    std::size_t _loop_count = 1;
    std::size_t _index = 0;

    explicit continuous_action(args &&args);

    void prepare();
};

struct parallel_action final : action {
    struct args {
        action_target_wptr target;
        std::unordered_set<std::shared_ptr<action>> actions;

        action::args action;
    };

    virtual ~parallel_action();

    std::vector<std::shared_ptr<action>> actions() const;

    void insert_action(std::shared_ptr<action>);
    void erase_action(std::shared_ptr<action> const &);

    [[nodiscard]] static parallel_action_ptr make_shared();
    [[nodiscard]] static parallel_action_ptr make_shared(args);

   private:
    std::unordered_set<std::shared_ptr<action>> _actions;

    explicit parallel_action(action::args &&);

    void prepare(args &&);
};

[[nodiscard]] ui::parallel_action_ptr make_action_sequence(std::vector<std::shared_ptr<action>> actions,
                                                           time_point_t const &begin_time);
}  // namespace yas::ui
