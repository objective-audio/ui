//
//  yas_ui_action.mm
//

#include "yas_stl_utils.h"
#include "yas_ui_action.h"
#include "yas_ui_node.h"

using namespace yas;
using namespace std::chrono;
using namespace std::chrono_literals;

#pragma mark - updatable_action

ui::updatable_action::updatable_action(std::shared_ptr<impl> &&impl) : protocol(std::move(impl)) {
}

ui::updatable_action::updatable_action(std::nullptr_t) : protocol(nullptr) {
}

bool ui::updatable_action::update(time_point_t const &time) {
    return impl_ptr<impl>()->update(time);
}

#pragma mark - action::impl

struct ui::action::impl : base::impl, updatable_action::impl {
    impl() {
    }

    impl(action::args &&args) : _begin_time(std::move(args.begin_time)), _delay(args.delay) {
    }

    bool update(time_point_t const &time) override {
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

    duration_t time_diff(time_point_t const &time) {
        return time - this->_begin_time - this->_delay;
    }

    weak<base> _target{nullptr};
    time_point_t _begin_time = system_clock::now();
    duration_t _delay{0.0};
    time_update_f _time_updater;
    completion_f _completion_handler;
};

#pragma mark - action

ui::action::action() : base(std::make_shared<impl>()) {
}

ui::action::action(action::args args) : base(std::make_shared<impl>(std::move(args))) {
}

ui::action::action(std::nullptr_t) : base(nullptr) {
}

ui::action::action(std::shared_ptr<impl> &&impl) : base(std::move(impl)) {
}

base ui::action::target() const {
    return impl_ptr<impl>()->_target.lock();
}

time_point<system_clock> const &ui::action::begin_time() const {
    return impl_ptr<impl>()->_begin_time;
}

double ui::action::delay() const {
    return impl_ptr<impl>()->_delay.count();
}

ui::action::time_update_f const &ui::action::time_updater() const {
    return impl_ptr<impl>()->_time_updater;
}

ui::action::completion_f const &ui::action::completion_handler() const {
    return impl_ptr<impl>()->_completion_handler;
}

void ui::action::set_target(weak<base> const &target) {
    impl_ptr<impl>()->_target = target;
}

void ui::action::set_time_updater(time_update_f handler) {
    impl_ptr<impl>()->_time_updater = std::move(handler);
}

void ui::action::set_completion_handler(completion_f handler) {
    impl_ptr<impl>()->_completion_handler = std::move(handler);
}

ui::updatable_action &ui::action::updatable() {
    if (!_updatable) {
        _updatable = ui::updatable_action{impl_ptr<ui::updatable_action::impl>()};
    }
    return _updatable;
}

#pragma mark - action::impl

struct ui::continuous_action::impl : action::impl {
    impl(continuous_action::args &&args)
        : action::impl(std::move(args.action)), _duration(args.duration), _loop_count(args.loop_count) {
        if (_duration < 0.0) {
            throw "duration underflow";
        }
    }

    virtual void value_update(double const value) {
        if (_value_updater) {
            _value_updater(value);
        }
    }

    auto end_time() {
        return this->_begin_time + this->_delay + duration_t{_duration} * _loop_count;
    }

    double _duration = 0.3;
    value_update_f _value_updater;
    transform_f _value_transformer;
    std::size_t _loop_count = 1;
    std::size_t _index = 0;
};

#pragma mark - continuous_action

ui::continuous_action::continuous_action() : continuous_action(continuous_action::args{}) {
}

ui::continuous_action::continuous_action(continuous_action::args args)
    : action(std::make_shared<impl>(std::move(args))) {
    set_time_updater([weak_action = to_weak(*this)](auto const &time) {
        if (auto action = weak_action.lock()) {
            auto impl_ptr = action.impl_ptr<continuous_action::impl>();
            auto const duration = impl_ptr->_duration;
            bool finished = false;

            if (impl_ptr->_loop_count > 0) {
                if (action.impl_ptr<continuous_action::impl>()->end_time() <= time) {
                    finished = true;
                }
            }

            float value = finished ? 1.0f : (fmod(impl_ptr->time_diff(time).count(), duration) / duration);

            if (auto const &transformer = action.value_transformer()) {
                value = transformer(value);
            }

            action.impl_ptr<continuous_action::impl>()->value_update(value);

            return finished;
        }

        return true;
    });
}

ui::continuous_action::continuous_action(std::nullptr_t) : action(nullptr) {
}

ui::continuous_action::~continuous_action() = default;

double ui::continuous_action::duration() const {
    return impl_ptr<impl>()->_duration;
}

ui::action::value_update_f const &ui::continuous_action::value_updater() const {
    return impl_ptr<impl>()->_value_updater;
}

ui::transform_f const &ui::continuous_action::value_transformer() const {
    return impl_ptr<impl>()->_value_transformer;
}

std::size_t ui::continuous_action::loop_count() const {
    return impl_ptr<impl>()->_loop_count;
}

void ui::continuous_action::set_value_updater(value_update_f updater) {
    impl_ptr<impl>()->_value_updater = std::move(updater);
}

void ui::continuous_action::set_value_transformer(transform_f transformer) {
    impl_ptr<impl>()->_value_transformer = std::move(transformer);
}

#pragma mark - parallel_action::impl

struct ui::parallel_action::impl : action::impl {
    impl(action::args &&args) : action::impl(std::move(args)) {
    }

    std::unordered_set<action> actions;
};

#pragma mark - parallel_action

ui::parallel_action::parallel_action() : parallel_action(args{}) {
}

ui::parallel_action::parallel_action(args args) : action(std::make_shared<impl>(std::move(args.action))) {
    set_time_updater([weak_action = to_weak(*this)](auto const &time) {
        if (auto parallel_action = weak_action.lock()) {
            auto &actions = parallel_action.impl_ptr<parallel_action::impl>()->actions;

            for (auto &action : to_vector(actions)) {
                if (action.updatable().update(time)) {
                    actions.erase(action);
                }
            }

            return actions.size() == 0;
        }

        return true;
    });

    set_target(std::move(args.target));

    impl_ptr<impl>()->actions = std::move(args.actions);
}

ui::parallel_action::parallel_action(std::nullptr_t) : action(nullptr) {
}

ui::parallel_action::~parallel_action() = default;

std::vector<ui::action> ui::parallel_action::actions() const {
    return to_vector(impl_ptr<impl>()->actions);
}

void ui::parallel_action::insert_action(action action) {
    impl_ptr<impl>()->actions.emplace(std::move(action));
}

void ui::parallel_action::erase_action(action const &action) {
    impl_ptr<impl>()->actions.erase(action);
}

#pragma mark -

ui::parallel_action ui::make_action_sequence(std::vector<action> actions, time_point_t const &begin_time) {
    parallel_action sequence{{.action = {.begin_time = begin_time}}};

    duration_t delay{0.0};

    for (auto &action : actions) {
        action.impl_ptr<action::impl>()->_begin_time = begin_time;
        action.impl_ptr<action::impl>()->_delay = delay;

        sequence.insert_action(action);

        if (auto continuous_action = cast<ui::continuous_action>(action)) {
            delay += duration_t{continuous_action.duration()};
        }
    }

    return sequence;
}
