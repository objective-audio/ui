//
//  yas_ui_action.mm
//

#include "yas_ui_action.h"
#include <cpp_utils/yas_stl_utils.h>
#include "yas_ui_node.h"

using namespace yas;
using namespace std::chrono;
using namespace std::chrono_literals;

#pragma mark - action

ui::action::action(action::args args) : _begin_time(std::move(args.begin_time)), _delay(args.delay) {
}

ui::action_target_ptr ui::action::target() const {
    return this->_target.lock();
}

time_point<system_clock> const &ui::action::begin_time() const {
    return this->_begin_time;
}

double ui::action::delay() const {
    return this->_delay.count();
}

ui::action::time_update_f const &ui::action::time_updater() const {
    return this->_time_updater;
}

ui::action::completion_f const &ui::action::completion_handler() const {
    return this->_completion_handler;
}

void ui::action::set_target(action_target_wptr const &target) {
    this->_target = target;
}

void ui::action::set_time_updater(time_update_f handler) {
    this->_time_updater = std::move(handler);
}

void ui::action::set_completion_handler(completion_f handler) {
    this->_completion_handler = std::move(handler);
}

bool ui::action::update(time_point_t const &time) {
    if (time < this->_begin_time + this->_delay) {
        return false;
    }

    auto const finished = this->_time_updater ? this->_time_updater(time) : true;

    if (finished && this->_completion_handler) {
        this->_completion_handler();
        this->_completion_handler = nullptr;
    }

    return finished;
}

ui::duration_t ui::action::time_diff(time_point_t const &time) {
    return time - this->_begin_time - this->_delay;
}

std::shared_ptr<ui::updatable_action> ui::action::updatable() {
    return std::dynamic_pointer_cast<updatable_action>(shared_from_this());
}

std::shared_ptr<ui::action> ui::action::make_shared() {
    return make_shared({});
}

std::shared_ptr<ui::action> ui::action::make_shared(args args) {
    return std::shared_ptr<action>(new action{std::move(args)});
}

#pragma mark - continuous_action

ui::continuous_action::continuous_action(continuous_action::args &&args)
    : action(std::move(args.action)), _duration(args.duration), _loop_count(args.loop_count) {
    if (this->_duration < 0.0) {
        throw std::underflow_error("duration underflow");
    }
}

ui::continuous_action::~continuous_action() = default;

double ui::continuous_action::duration() const {
    return this->_duration;
}

ui::action::value_update_f const &ui::continuous_action::value_updater() const {
    return this->_value_updater;
}

ui::transform_f const &ui::continuous_action::value_transformer() const {
    return this->_value_transformer;
}

std::size_t ui::continuous_action::loop_count() const {
    return this->_loop_count;
}

void ui::continuous_action::set_value_updater(value_update_f updater) {
    this->_value_updater = std::move(updater);
}

void ui::continuous_action::set_value_transformer(transform_f transformer) {
    this->_value_transformer = std::move(transformer);
}

void ui::continuous_action::prepare() {
    set_time_updater([weak_action = to_weak(std::dynamic_pointer_cast<continuous_action>(shared_from_this()))](
                         time_point_t const &time) {
        if (auto action = weak_action.lock()) {
            auto const duration = action->_duration;
            bool finished = false;

            if (action->_loop_count > 0) {
                auto end_time = action->_begin_time + action->_delay + duration_t{duration} * action->_loop_count;
                if (end_time <= time) {
                    finished = true;
                }
            }

            float value = finished ? 1.0f : (fmod(action->time_diff(time).count(), duration) / duration);

            if (auto const &transformer = action->value_transformer()) {
                value = transformer(value);
            }

            if (action->_value_updater) {
                action->_value_updater(value);
            }

            return finished;
        }

        return true;
    });
}

std::shared_ptr<ui::continuous_action> ui::continuous_action::make_shared() {
    return make_shared({});
}

std::shared_ptr<ui::continuous_action> ui::continuous_action::make_shared(args args) {
    auto shared = std::shared_ptr<continuous_action>(new continuous_action{std::move(args)});
    shared->prepare();
    return shared;
}

#pragma mark - parallel_action

ui::parallel_action::parallel_action(action::args &&args) : action(std::move(args)) {
}

ui::parallel_action::~parallel_action() = default;

std::vector<std::shared_ptr<ui::action>> ui::parallel_action::actions() const {
    return to_vector(this->_actions);
}

void ui::parallel_action::insert_action(std::shared_ptr<action> action) {
    this->_actions.emplace(std::move(action));
}

void ui::parallel_action::erase_action(std::shared_ptr<action> const &action) {
    this->_actions.erase(action);
}

void ui::parallel_action::prepare(args &&args) {
    set_time_updater(
        [weak_action = to_weak(std::dynamic_pointer_cast<parallel_action>(shared_from_this()))](auto const &time) {
            if (auto parallel_action = weak_action.lock()) {
                auto &actions = parallel_action->_actions;

                for (auto &action : to_vector(actions)) {
                    if (action->updatable()->update(time)) {
                        actions.erase(action);
                    }
                }

                return actions.size() == 0;
            }

            return true;
        });

    set_target(std::move(args.target));

    this->_actions = std::move(args.actions);
}

std::shared_ptr<ui::parallel_action> ui::parallel_action::make_shared() {
    return make_shared({});
}

std::shared_ptr<ui::parallel_action> ui::parallel_action::make_shared(args args) {
    auto shared = std::shared_ptr<parallel_action>(new parallel_action{std::move(args.action)});
    shared->prepare(std::move(args));
    return shared;
}

#pragma mark -

std::shared_ptr<ui::parallel_action> ui::make_action_sequence(std::vector<std::shared_ptr<action>> actions,
                                                              time_point_t const &begin_time) {
    auto sequence = parallel_action::make_shared({.action = {.begin_time = begin_time}});

    duration_t delay{0.0};

    for (std::shared_ptr<ui::action> &action : actions) {
        action->_begin_time = begin_time;
        action->_delay = delay;

        sequence->insert_action(action);

        if (auto continuous_action = std::dynamic_pointer_cast<ui::continuous_action>(action)) {
            delay += duration_t{continuous_action->duration()};
        }
    }

    return sequence;
}
