//
//  yas_ui_action.mm
//

#include "yas_ui_action.h"
#include <cpp_utils/yas_stl_utils.h>
#include "yas_ui_node.h"

using namespace yas;
using namespace yas::ui;
using namespace std::chrono;
using namespace std::chrono_literals;

#pragma mark - action

action::action(action_args args)
    : _target(std::move(args.target)),
      _begin_time(std::move(args.begin_time)),
      _delay(args.delay),
      _completion(std::move(args.completion)) {
}

action_target_ptr action::target() const {
    return this->_target.lock();
}

time_point<system_clock> const &action::begin_time() const {
    return this->_begin_time;
}

double action::delay() const {
    return this->_delay.count();
}

action_completion_f const &action::completion() const {
    return this->_completion;
}

bool action::update(time_point_t const &time) {
    if (time < this->_begin_time + this->_delay) {
        return false;
    }

    auto const finished = this->time_updater ? this->time_updater(time) : true;

    if (finished && this->_completion) {
        this->_completion();
        this->_completion = nullptr;
    }

    return finished;
}

duration_t action::time_diff(time_point_t const &time) {
    return time - this->_begin_time - this->_delay;
}

action_ptr action::make_shared() {
    return make_shared({});
}

action_ptr action::make_shared(action_args args) {
    return std::shared_ptr<action>(new action{std::move(args)});
}

action_ptr action::make_continuous() {
    return make_continuous({});
}

action_ptr action::make_continuous(continuous_action_args continuous_args) {
    auto action = make_shared(std::move(continuous_args.action));

    action->time_updater = [weak_action = to_weak(action), continuous_args](time_point_t const &time) {
        if (auto action = weak_action.lock()) {
            auto const duration = continuous_args.duration;
            bool finished = false;

            if (continuous_args.loop_count > 0) {
                auto end_time =
                    action->_begin_time + action->_delay + duration_t{duration} * continuous_args.loop_count;
                if (end_time <= time) {
                    finished = true;
                }
            }

            float value = finished ? 1.0f : (fmod(action->time_diff(time).count(), duration) / duration);

            if (auto const &transformer = continuous_args.value_transformer) {
                value = transformer(value);
            }

            if (auto const &updater = continuous_args.value_updater) {
                updater(value);
            }

            return finished;
        } else {
            return true;
        }
    };

    return action;
}

#pragma mark - continuous_action

continuous_action::continuous_action(continuous_action_args &&args)
    : _duration(args.duration),
      _loop_count(args.loop_count),
      _value_updater(std::move(args.value_updater)),
      _value_transformer(std::move(args.value_transformer)) {
    if (this->_duration < 0.0) {
        throw std::underflow_error("duration underflow");
    }
}

double continuous_action::duration() const {
    return this->_duration;
}

std::size_t continuous_action::loop_count() const {
    return this->_loop_count;
}

continuous_action::value_update_f const &continuous_action::value_updater() const {
    return this->_value_updater;
}

transform_f const &continuous_action::value_transformer() const {
    return this->_value_transformer;
}

std::shared_ptr<continuous_action> continuous_action::make_shared(continuous_action_args args) {
    return std::shared_ptr<continuous_action>(new continuous_action{std::move(args)});
}

#pragma mark -

std::shared_ptr<action> ui::action::make_sequence(std::vector<sequence_action> &&seq_actions, action_args &&args) {
    auto sequence = parallel_action::make_shared({.action = args});

    duration_t delay{args.delay};

    for (sequence_action const &seq_action : seq_actions) {
        seq_action.action->_begin_time = args.begin_time;
        seq_action.action->_delay = delay;

        sequence->insert_action(seq_action.action);

        delay += duration_t(seq_action.duration);
    }

    return sequence->raw_action();
}

#pragma mark -

parallel_action::parallel_action(parallel_action_args &&args)
    : _raw_action(action::make_shared(std::move(args.action))),
      _actions(std::make_shared<std::unordered_set<action_ptr>>(std::move(args.actions))) {
    this->_raw_action->time_updater = [actions = this->_actions](auto const &time) {
        for (auto const &updating : to_vector(*actions)) {
            if (updating->update(time)) {
                actions->erase(updating);
            }
        }

        return actions->size() == 0;
    };
}

action_ptr const &parallel_action::raw_action() const {
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

parallel_action_ptr parallel_action::make_shared(parallel_action_args &&args) {
    return parallel_action_ptr(new parallel_action{std::move(args)});
}
