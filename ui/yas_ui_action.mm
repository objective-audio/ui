//
//  yas_ui_action.mm
//

#include <unordered_set>
#include "yas_stl_utils.h"
#include "yas_ui_action.h"
#include "yas_ui_node.h"

using namespace yas;
using namespace std::chrono;
using namespace std::chrono_literals;

#pragma mark - updatable_action

ui::updatable_action::updatable_action(std::shared_ptr<impl> &&impl) : protocol(std::move(impl)) {
}

bool ui::updatable_action::update(time_point_t const &time) {
    return impl_ptr<impl>()->update(time);
}

#pragma mark - action::impl

struct ui::action::impl : public base::impl, public updatable_action::impl {
    impl() {
    }

    impl(action_args &&args) : start_time(std::move(args.start_time)), delay(args.delay) {
    }

    bool update(time_point_t const &time) override {
        if (time < start_time + delay) {
            return false;
        }

        auto const finished = time_updater ? time_updater(time) : true;

        if (finished && completion_handler) {
            completion_handler();
            completion_handler = nullptr;
        }

        return finished;
    }

    duration_t time_diff(time_point_t const &time) {
        return time - start_time - delay;
    }

    weak<ui::node> target{nullptr};
    time_point_t start_time = system_clock::now();
    duration_t delay{0.0};
    action_time_update_f time_updater;
    action_completion_f completion_handler;
};

#pragma mark - action

ui::action::action() : super_class(std::make_shared<impl>()) {
}

ui::action::action(action_args args) : super_class(std::make_shared<impl>(std::move(args))) {
}

ui::action::action(std::nullptr_t) : super_class(nullptr) {
}

ui::action::action(std::shared_ptr<impl> &&impl) : super_class(std::move(impl)) {
}

ui::node ui::action::target() const {
    return impl_ptr<impl>()->target.lock();
}

time_point<system_clock> const &ui::action::start_time() const {
    return impl_ptr<impl>()->start_time;
}

double ui::action::delay() const {
    return impl_ptr<impl>()->delay.count();
}

ui::action_time_update_f const &ui::action::time_updater() const {
    return impl_ptr<impl>()->time_updater;
}

ui::action_completion_f const &ui::action::completion_handler() const {
    return impl_ptr<impl>()->completion_handler;
}

void ui::action::set_target(ui::node const &target) {
    impl_ptr<impl>()->target = target;
}

void ui::action::set_time_updater(action_time_update_f handler) {
    impl_ptr<impl>()->time_updater = std::move(handler);
}

void ui::action::set_completion_handler(action_completion_f handler) {
    impl_ptr<impl>()->completion_handler = std::move(handler);
}

ui::updatable_action ui::action::updatable() {
    return ui::updatable_action{impl_ptr<ui::updatable_action::impl>()};
}

#pragma mark - action::impl

struct ui::continuous_action::impl : public action::impl {
    impl() {
    }

    impl(continuous_action_args &&args)
        : action::impl(std::move(args.action)), duration(args.duration), loop_count(args.loop_count) {
        if (duration < 0.0) {
            throw "duration underflow";
        }
    }

    virtual void value_update(double const value) {
        if (value_updater) {
            value_updater(value);
        }
    }

    auto end_time() {
        return start_time + delay + duration_t{duration} * loop_count;
    }

    double duration = 0.3;
    action_value_update_f value_updater;
    action_transform_f value_transformer;
    std::size_t loop_count = 1;
    std::size_t index = 0;
};

#pragma mark - continuous_action

ui::continuous_action::continuous_action() : continuous_action(continuous_action_args{}) {
}

ui::continuous_action::continuous_action(continuous_action_args args)
    : super_class(std::make_shared<impl>(std::move(args))) {
    set_time_updater([weak_action = to_weak(*this)](auto const &time) {
        if (auto action = weak_action.lock()) {
            auto impl_ptr = action.impl_ptr<continuous_action::impl>();
            auto const duration = impl_ptr->duration;
            bool finished = false;

            if (impl_ptr->loop_count > 0) {
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

ui::continuous_action::continuous_action(std::nullptr_t) : super_class(nullptr) {
}

double ui::continuous_action::duration() const {
    return impl_ptr<impl>()->duration;
}

ui::action_value_update_f const &ui::continuous_action::value_updater() const {
    return impl_ptr<impl>()->value_updater;
}

ui::action_transform_f const &ui::continuous_action::value_transformer() const {
    return impl_ptr<impl>()->value_transformer;
}

std::size_t ui::continuous_action::loop_count() const {
    return impl_ptr<impl>()->loop_count;
}

void ui::continuous_action::set_value_updater(action_value_update_f updater) {
    impl_ptr<impl>()->value_updater = std::move(updater);
}

void ui::continuous_action::set_value_transformer(action_transform_f transformer) {
    impl_ptr<impl>()->value_transformer = std::move(transformer);
}

#pragma mark - translate_action

ui::continuous_action ui::make_action(translate_action_args args) {
    ui::continuous_action action{std::move(args.continuous_action)};

    action.set_value_updater([args = std::move(args), weak_action = to_weak(action)](double const value) {
        if (auto action = weak_action.lock()) {
            if (auto target = action.target()) {
                target.set_position((args.end_position - args.start_position) * (float)value + args.start_position);
            }
        }
    });

    return action;
}

#pragma mark - rotate_action

ui::continuous_action ui::make_action(rotate_action_args args) {
    ui::continuous_action action{std::move(args.continuous_action)};

    action.set_value_updater([args = std::move(args), weak_action = to_weak(action)](double const value) {
        if (auto action = weak_action.lock()) {
            if (auto target = action.target()) {
                auto const end_angle = args.end_angle;
                auto start_angle = args.start_angle;

                if (args.is_shortest) {
                    if ((end_angle - start_angle) > 180.0f) {
                        start_angle += 360.0f;
                    } else if ((end_angle - start_angle) < -180.0f) {
                        start_angle -= 360.0f;
                    }
                }

                target.set_angle((end_angle - start_angle) * value + start_angle);
            }
        }
    });

    return action;
}

#pragma mark - scale_action

ui::continuous_action ui::make_action(ui::scale_action_args args) {
    ui::continuous_action action{std::move(args.continuous_action)};

    action.set_value_updater([args = std::move(args), weak_action = to_weak(action)](double const value) {
        if (auto action = weak_action.lock()) {
            if (auto target = action.target()) {
                target.set_scale((args.end_scale - args.start_scale) * (float)value + args.start_scale);
            }
        }
    });

    return action;
}

#pragma mark - color_action

ui::continuous_action ui::make_action(ui::color_action_args args) {
    ui::continuous_action action{std::move(args.continuous_action)};

    action.set_value_updater([args = std::move(args), weak_action = to_weak(action)](double const value) {
        if (auto action = weak_action.lock()) {
            if (auto target = action.target()) {
                target.set_color((args.end_color - args.start_color) * (float)value + args.start_color);
            }
        }
    });

    return action;
}

#pragma mark - parallel_action::impl

struct ui::parallel_action::impl : public action::impl {
    impl(action_args &&args) : action::impl(std::move(args)) {
    }

    std::unordered_set<action> actions;
};

#pragma mark - parallel_action

ui::parallel_action::parallel_action() : parallel_action(action_args{}) {
}

ui::parallel_action::parallel_action(action_args args) : super_class(std::make_shared<impl>(std::move(args))) {
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
}

ui::parallel_action::parallel_action(std::nullptr_t) : super_class(nullptr) {
}

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

ui::parallel_action ui::make_action_sequence(std::vector<action> actions, time_point_t const &start_time) {
    parallel_action sequence{{.start_time = start_time}};

    duration_t delay{0.0};

    for (auto &action : actions) {
        action.impl_ptr<action::impl>()->start_time = start_time;
        action.impl_ptr<action::impl>()->delay = delay;

        sequence.insert_action(action);

        if (auto continuous_action = cast<ui::continuous_action>(action)) {
            delay += duration_t{continuous_action.duration()};
        }
    }

    return sequence;
}
