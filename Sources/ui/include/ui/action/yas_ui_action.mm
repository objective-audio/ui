//
//  yas_ui_action.mm
//

#include "yas_ui_action.h"

#include <cpp-utils/yas_stl_utils.h>
#include <ui/node/yas_ui_node.h>

using namespace yas;
using namespace yas::ui;
using namespace std::chrono;
using namespace std::chrono_literals;

#pragma mark - action

action::action(action_args &&args)
    : _group(std::move(args.group)),
      _begin_time(std::move(args.begin_time)),
      _delay(args.delay),
      _time_updater(std::move(args.time_updater)),
      _completion(std::move(args.completion)) {
}

std::shared_ptr<action_group> action::group() const {
    return this->_group;
}

time_point<system_clock> const &action::begin_time() const {
    return this->_begin_time;
}

double action::delay() const {
    return this->_delay.count();
}

action_time_update_f const &action::time_updater() const {
    return this->_time_updater;
}

action_completion_f const &action::completion() const {
    return this->_completion;
}

bool action::update(time_point_t const &time) {
    if (time < this->_begin_time + this->_delay) {
        return false;
    }

    auto const finished = this->_time_updater ? this->_time_updater(time, *this) : true;

    if (finished && this->_completion) {
        this->_completion();
        this->_completion = nullptr;
    }

    return finished;
}

duration_t action::time_diff(time_point_t const &time) const {
    return time - this->_begin_time - this->_delay;
}

std::shared_ptr<action> action::make_shared() {
    return make_shared({});
}

std::shared_ptr<action> action::make_shared(action_args &&args) {
    return std::shared_ptr<action>(new action{std::move(args)});
}

std::shared_ptr<action> action::make_continuous(continuous_action_args &&continuous_args) {
    auto args = action_args{.group = std::move(continuous_args.group),
                            .begin_time = std::move(continuous_args.begin_time),
                            .delay = std::move(continuous_args.delay),
                            .completion = std::move(continuous_args.completion)};

    args.time_updater = [continuous_args](time_point_t const &time, ui::action const &action) {
        auto const duration = continuous_args.duration;
        bool finished = false;

        if (continuous_args.loop_count > 0) {
            auto end_time = action._begin_time + action._delay + duration_t{duration} * continuous_args.loop_count;
            if (end_time <= time) {
                finished = true;
            }
        }

        float value = finished ? 1.0f : (fmod(action.time_diff(time).count(), duration) / duration);

        if (auto const &transformer = continuous_args.value_transformer) {
            value = transformer(value);
        }

        if (auto const &updater = continuous_args.value_updater) {
            updater(value);
        }

        return finished;
    };

    return make_shared(std::move(args));
}

std::shared_ptr<action> ui::action::make_sequence(sequence_action_args &&args) {
    auto sequence = parallel_action::make_shared({.group = std::move(args.group),
                                                  .begin_time = args.begin_time,
                                                  .delay = args.delay,
                                                  .completion = std::move(args.completion)});

    duration_t delay{args.delay};

    for (auto const &element : args.elements) {
        auto action = element.action->make_delayed(args.begin_time, delay.count());
        sequence->insert_action(std::move(action));
        delay += duration_t(element.duration);
    }

    return sequence->raw_action();
}

std::shared_ptr<action> action::make_delayed(time_point_t const &begin_time, double const delay) const {
    return make_shared({.group = this->_group,
                        .begin_time = begin_time,
                        .delay = delay,
                        .time_updater = this->_time_updater,
                        .completion = this->_completion});
}

#pragma mark -

namespace yas::ui::parallel_action_utils {
action_args time_updater_replaced_args(parallel_action_args &&parallel_args,
                                       std::shared_ptr<std::unordered_set<std::shared_ptr<action>>> const &actions) {
    action_args args{.group = std::move(parallel_args.group),
                     .begin_time = std::move(parallel_args.begin_time),
                     .delay = std::move(parallel_args.delay),
                     .completion = std::move(parallel_args.completion)};

    args.time_updater = [actions](auto const &time, ui::action const &action) {
        for (auto const &updating : to_vector(*actions)) {
            if (updating->update(time)) {
                actions->erase(updating);
            }
        }

        return actions->size() == 0;
    };

    return args;
}
}  // namespace yas::ui::parallel_action_utils

parallel_action::parallel_action(parallel_action_args &&args)
    : _actions(std::make_shared<std::unordered_set<std::shared_ptr<action>>>(std::move(args.actions))),
      _raw_action(
          action::make_shared(parallel_action_utils::time_updater_replaced_args(std::move(args), this->_actions))) {
}

std::shared_ptr<action> const &parallel_action::raw_action() const {
    return this->_raw_action;
}

std::vector<std::shared_ptr<action>> parallel_action::actions() const {
    return to_vector(*this->_actions);
}

std::size_t parallel_action::action_count() const {
    return this->_actions->size();
}

void parallel_action::insert_action(std::shared_ptr<action> action) {
    this->_actions->emplace(std::move(action));
}

void parallel_action::erase_action(std::shared_ptr<action> const &action) {
    this->_actions->erase(action);
}

std::shared_ptr<parallel_action> parallel_action::make_shared(parallel_action_args &&args) {
    return std::shared_ptr<parallel_action>(new parallel_action{std::move(args)});
}
