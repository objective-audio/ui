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

action::action(action_args args) : _begin_time(std::move(args.begin_time)), _delay(args.delay) {
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

void action::set_target(action_target_wptr const &target) {
    this->_target = target;
}

bool action::update(time_point_t const &time) {
    if (time < this->_begin_time + this->_delay) {
        return false;
    }

    auto const finished = this->time_updater ? this->time_updater(time) : true;

    if (finished && this->completion_handler) {
        this->completion_handler();
        this->completion_handler = nullptr;
    }

    return finished;
}

duration_t action::time_diff(time_point_t const &time) {
    return time - this->_begin_time - this->_delay;
}

bool action::is_continous() const {
    return this->_continuous != nullptr;
}

bool action::is_parallel() const {
    return this->_parallel != nullptr;
}

continuous_action_ptr const &action::continuous() const {
    return this->_continuous;
}

parallel_action_ptr const &action::parallel() const {
    return this->_parallel;
}

action_ptr action::make_shared() {
    return make_shared({});
}

action_ptr action::make_shared(action_args args) {
    return std::shared_ptr<action>(new action{std::move(args)});
}

action_ptr action::make_continuous() {
    return make_continuous({}, {});
}

action_ptr action::make_continuous(action_args args, continuous_action_args continuous_args) {
    auto action = make_shared(std::move(args));
    action->_continuous = continuous_action::make_shared(std::move(continuous_args));

    action->time_updater = [weak_action = to_weak(action)](time_point_t const &time) {
        if (auto action = weak_action.lock()) {
            auto const duration = action->continuous()->duration();
            bool finished = false;

            if (action->continuous()->loop_count() > 0) {
                auto end_time =
                    action->_begin_time + action->_delay + duration_t{duration} * action->continuous()->loop_count();
                if (end_time <= time) {
                    finished = true;
                }
            }

            float value = finished ? 1.0f : (fmod(action->time_diff(time).count(), duration) / duration);

            if (auto const &transformer = action->continuous()->value_transformer) {
                value = transformer(value);
            }

            if (auto const &updator = action->continuous()->value_updater) {
                updator(value);
            }

            return finished;
        } else {
            return true;
        }
    };

    return action;
}

action_ptr action::make_parallel() {
    return make_parallel({}, {});
}

action_ptr action::make_parallel(action_args args, parallel_action_args parallel_args) {
    auto action = action::make_shared(std::move(args));
    action->set_target(std::move(parallel_args.target));
    action->_parallel = parallel_action::make_shared(std::move(parallel_args.actions));

    action->time_updater = [parallel = action->_parallel](auto const &time) {
        for (auto const &updating : parallel->actions()) {
            if (updating->update(time)) {
                parallel->erase_action(updating);
            }
        }

        return parallel->action_count() == 0;
    };

    return action;
}

#pragma mark - continuous_action

continuous_action::continuous_action(continuous_action_args &&args)
    : _duration(args.duration), _loop_count(args.loop_count) {
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

std::shared_ptr<continuous_action> continuous_action::make_shared(continuous_action_args args) {
    return std::shared_ptr<continuous_action>(new continuous_action{std::move(args)});
}

#pragma mark - parallel_action

parallel_action::parallel_action(std::unordered_set<action_ptr> &&actions) : _actions(std::move(actions)) {
}

std::vector<std::shared_ptr<action>> parallel_action::actions() const {
    return to_vector(this->_actions);
}

std::size_t parallel_action::action_count() const {
    return this->_actions.size();
}

void parallel_action::insert_action(std::shared_ptr<action> action) {
    this->_actions.emplace(std::move(action));
}

void parallel_action::erase_action(std::shared_ptr<action> const &action) {
    this->_actions.erase(action);
}

parallel_action_ptr parallel_action::make_shared(std::unordered_set<action_ptr> &&actions) {
    return std::shared_ptr<parallel_action>(new parallel_action{std::move(actions)});
}

#pragma mark -

std::shared_ptr<action> ui::action::make_sequence(std::vector<std::shared_ptr<action>> actions,
                                                  time_point_t const &begin_time) {
    auto sequence = action::make_parallel({.begin_time = begin_time}, {});

    duration_t delay{0.0};

    for (std::shared_ptr<ui::action> const &action : actions) {
        action->_begin_time = begin_time;
        action->_delay = delay;

        sequence->parallel()->insert_action(action);

        if (auto const continuous_action = action->continuous()) {
            delay += duration_t{continuous_action->duration()};
        }
    }

    return sequence;
}
