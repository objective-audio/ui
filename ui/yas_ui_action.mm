//
//  yas_ui_action.mm
//

#include <unordered_set>
#include "yas_each_index.h"
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

#pragma mark - action_utils

namespace yas {
namespace ui {
    namespace action_utils {
        static std::size_t constexpr _curve_frames = 256;

        static std::vector<float> make_curve_vector(std::function<float(float const)> const &func) {
            static std::size_t constexpr _vector_size = _curve_frames + 2;
            std::vector<float> curve_vector;
            curve_vector.reserve(_vector_size);
            for (auto const &i : each_index<std::size_t>(_vector_size)) {
                float const pos = float(i) / _curve_frames;
                float val = (pos < 1.0f) ? func(pos) : 1.0f;
                curve_vector.push_back(val);
            }
            return curve_vector;
        }

        static float convert_value(std::vector<float> const &vector, float pos) {
            float const frame = pos * _curve_frames;
            std::size_t const cur_index = frame;
            float const cur_val = vector.at(cur_index);
            float const next_val = vector.at(cur_index + 1);
            float const frac = frame - cur_index;
            return cur_val + (next_val - cur_val) * frac;
        }
    }
}
}

ui::action_transform_f const &ui::ease_in_transformer() {
    static action_transform_f const _transformer = [](float const pos) {
        static auto curve =
            action_utils::make_curve_vector([](float const pos) { return sinf((pos - 1.0f) * M_PI_2) + 1.0f; });
        return action_utils::convert_value(curve, pos);
    };

    return _transformer;
}

ui::action_transform_f const &ui::ease_out_transformer() {
    static action_transform_f const _transformer = [](float const pos) {
        static auto curve = action_utils::make_curve_vector([](float const pos) { return sinf(pos * M_PI_2); });
        return action_utils::convert_value(curve, pos);
    };

    return _transformer;
}

ui::action_transform_f const &ui::ease_in_out_transformer() {
    static action_transform_f const _transformer = [](float const pos) {
        static auto curve = action_utils::make_curve_vector(
            [](float const pos) { return (sinf((pos * 2.0f - 1.0f) * M_PI_2) + 1.0f) * 0.5f; });
        return action_utils::convert_value(curve, pos);
    };

    return _transformer;
}

#pragma mark - action::impl

struct ui::action::impl : public base::impl, public updatable_action::impl {
    bool update(time_point_t const &time) override {
        if (time < start_time + delay) {
            return false;
        }

        auto const finished = update_handler ? update_handler(time) : true;

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
    action_update_f update_handler;
    action_completion_f completion_handler;
};

#pragma mark - action

ui::action::action() : super_class(std::make_shared<impl>()) {
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

ui::action_update_f const &ui::action::update_handler() const {
    return impl_ptr<impl>()->update_handler;
}

ui::action_completion_f const &ui::action::completion_handler() const {
    return impl_ptr<impl>()->completion_handler;
}

void ui::action::set_target(ui::node target) {
    impl_ptr<impl>()->target = target;
}

void ui::action::set_start_time(time_point_t time) {
    impl_ptr<impl>()->start_time = std::move(time);
}

void ui::action::set_delay(double const delay) {
    impl_ptr<impl>()->delay = duration_t{delay};
}

void ui::action::set_update_handler(action_update_f handler) {
    impl_ptr<impl>()->update_handler = std::move(handler);
}

void ui::action::set_completion_handler(action_completion_f handler) {
    impl_ptr<impl>()->completion_handler = std::move(handler);
}

ui::updatable_action ui::action::updatable() {
    return ui::updatable_action{impl_ptr<ui::updatable_action::impl>()};
}

#pragma mark - action::impl

struct ui::one_shot_action::impl : public action::impl {
    virtual void value_update(double const value) = 0;

    double duration = 0.3;
    action_transform_f value_transformer;
};

#pragma mark - one_shot_action

ui::one_shot_action::one_shot_action(std::nullptr_t) : super_class(nullptr) {
}

ui::one_shot_action::one_shot_action(std::shared_ptr<impl> &&impl) : super_class(std::move(impl)) {
    set_update_handler([weak_action = to_weak(*this)](auto const &time) {
        if (auto action = weak_action.lock()) {
            auto impl_ptr = action.impl_ptr<one_shot_action::impl>();

            auto const time_diff = impl_ptr->time_diff(time);
            auto value = time_diff.count() / impl_ptr->duration;
            bool finished = false;

            if (value >= 1.0) {
                value = 1.0;
                finished = true;
            } else if (value < 0) {
                value = 0;
            }

            if (auto const &transformer = impl_ptr->value_transformer) {
                value = transformer(value);
            }

            impl_ptr->value_update(value);

            return finished;
        }

        return true;
    });
}

double ui::one_shot_action::duration() const {
    return impl_ptr<impl>()->duration;
}

ui::action_transform_f const &ui::one_shot_action::value_transformer() const {
    return impl_ptr<impl>()->value_transformer;
}

void ui::one_shot_action::set_duration(double const &duration) {
    if (duration < 0.0) {
        throw "duration underflow";
    }

    impl_ptr<impl>()->duration = duration;
}

void ui::one_shot_action::set_value_transformer(action_transform_f transformer) {
    impl_ptr<impl>()->value_transformer = std::move(transformer);
}

#pragma mark - translate_action

struct ui::translate_action::impl : public ui::one_shot_action::impl {
    void value_update(double const value) override {
        if (auto locked_target = target.lock()) {
            locked_target.set_position((end_position - start_position) * (float)value + start_position);
        }
    }

    simd::float2 start_position;
    simd::float2 end_position;
};

ui::translate_action::translate_action() : super_class(std::make_shared<impl>()) {
}

ui::translate_action::translate_action(std::nullptr_t) : super_class(nullptr) {
}

simd::float2 const &ui::translate_action::start_position() const {
    return impl_ptr<impl>()->start_position;
}

simd::float2 const &ui::translate_action::end_position() const {
    return impl_ptr<impl>()->end_position;
}

void ui::translate_action::set_start_position(simd::float2 pos) {
    impl_ptr<impl>()->start_position = std::move(pos);
}

void ui::translate_action::set_end_position(simd::float2 pos) {
    impl_ptr<impl>()->end_position = std::move(pos);
}

#pragma mark - rotate_action

struct ui::rotate_action::impl : public ui::one_shot_action::impl {
    void value_update(double const value) override {
        if (shortest) {
            if ((end_angle - start_angle) > 180.0f) {
                start_angle += 360.0f;
            } else if ((end_angle - start_angle) < -180.0f) {
                start_angle -= 360.0f;
            }
        }

        if (auto locked_target = target.lock()) {
            locked_target.set_angle((end_angle - start_angle) * value + start_angle);
        }
    }

    float start_angle;
    float end_angle;
    bool shortest;
};

ui::rotate_action::rotate_action() : super_class(std::make_shared<impl>()) {
}

ui::rotate_action::rotate_action(std::nullptr_t) : super_class(nullptr) {
}

float ui::rotate_action::start_angle() const {
    return impl_ptr<impl>()->start_angle;
}

float ui::rotate_action::end_angle() const {
    return impl_ptr<impl>()->end_angle;
}

bool ui::rotate_action::is_shortest() const {
    return impl_ptr<impl>()->shortest;
}

void ui::rotate_action::set_start_angle(float const angle) {
    impl_ptr<impl>()->start_angle = angle;
}

void ui::rotate_action::set_end_angle(float const angle) {
    impl_ptr<impl>()->end_angle = angle;
}

void ui::rotate_action::set_shortest(bool const shortest) {
    impl_ptr<impl>()->shortest = shortest;
}

#pragma mark - scale_action

struct ui::scale_action::impl : public ui::one_shot_action::impl {
    void value_update(double const value) override {
        if (auto locked_target = target.lock()) {
            locked_target.set_scale((end_scale - start_scale) * (float)value + start_scale);
        }
    }

    simd::float2 start_scale;
    simd::float2 end_scale;
};

ui::scale_action::scale_action() : super_class(std::make_shared<impl>()) {
}

ui::scale_action::scale_action(std::nullptr_t) : super_class(nullptr) {
}

simd::float2 const &ui::scale_action::start_scale() const {
    return impl_ptr<impl>()->start_scale;
}

simd::float2 const &ui::scale_action::end_scale() const {
    return impl_ptr<impl>()->end_scale;
}

void ui::scale_action::set_start_scale(simd::float2 scale) {
    impl_ptr<impl>()->start_scale = std::move(scale);
}

void ui::scale_action::set_end_scale(simd::float2 scale) {
    impl_ptr<impl>()->end_scale = std::move(scale);
}

#pragma mark - color_action

struct ui::color_action::impl : public ui::one_shot_action::impl {
    void value_update(double const value) override {
        if (auto locked_target = target.lock()) {
            locked_target.set_color((end_color - start_color) * (float)value + start_color);
        }
    }

    simd::float4 start_color;
    simd::float4 end_color;
};

ui::color_action::color_action() : super_class(std::make_shared<impl>()) {
}

ui::color_action::color_action(std::nullptr_t) : super_class(nullptr) {
}

simd::float4 const &ui::color_action::start_color() const {
    return impl_ptr<impl>()->start_color;
}

simd::float4 const &ui::color_action::end_color() const {
    return impl_ptr<impl>()->end_color;
}

void ui::color_action::set_start_color(simd::float4 color) {
    impl_ptr<impl>()->start_color = std::move(color);
}

void ui::color_action::set_end_color(simd::float4 color) {
    impl_ptr<impl>()->end_color = std::move(color);
}

#pragma mark - parallel_action::impl

struct ui::parallel_action::impl : public action::impl {
    impl() : actions() {
    }

    std::unordered_set<action> actions;
};

#pragma mark - parallel_action

ui::parallel_action::parallel_action() : super_class(std::make_shared<impl>()) {
    set_update_handler([weak_action = to_weak(*this)](auto const &time) {
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
    parallel_action sequence;
    sequence.set_start_time(start_time);

    duration_t delay{0.0};

    for (auto &action : actions) {
        action.set_start_time(start_time);
        action.set_delay(delay.count());

        sequence.insert_action(action);

        if (auto one_shot_action = cast<ui::one_shot_action>(action)) {
            delay += duration_cast<milliseconds>(duration_t{one_shot_action.duration()});
        }
    }

    return sequence;
}
