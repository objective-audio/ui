//
//  yas_ui_action.mm
//

#include "yas_each_index.h"
#include "yas_ui_action.h"
#include "yas_ui_node.h"

using namespace yas;

#pragma mark - updatable_action

ui::updatable_action::updatable_action(std::shared_ptr<impl> &&impl) : protocol(std::move(impl)) {
}

void ui::updatable_action::update(time_point_t const &time) {
    impl_ptr<impl>()->update(time);
}

void ui::updatable_action::set_finish_handler(action_finish_f handler) {
    impl_ptr<impl>()->set_finish_handler(std::move(handler));
}

#pragma mark - action_utils

namespace yas {
namespace ui {
    namespace action_utils {
        static bool _curve_setup_finished = false;
        static std::size_t constexpr _curve_frames = 256;
        static float _ease_in_curve[_curve_frames + 1];
        static float _ease_out_curve[_curve_frames + 1];
        static float _ease_in_out_curve[_curve_frames + 1];

        static void setup_curve() {
            if (_curve_setup_finished) {
                return;
            }

            for (auto const &i : each_index<std::size_t>(_curve_frames + 1)) {
                float pos = (float)i / _curve_frames;
                _ease_in_curve[i] = sinf((pos - 1.0f) * M_PI_2) + 1.0f;
                _ease_out_curve[i] = sinf(pos * M_PI_2);
                _ease_in_out_curve[i] = (sinf((pos * 2.0f - 1.0f) * M_PI_2) + 1.0f) * 0.5f;
            }

            _curve_setup_finished = true;
        }

        static float _convert_value(float *ptr, float pos) {
            float frame = pos * _curve_frames;
            SInt32 index = frame;
            float frac = frame - index;
            float curVal = ptr[index];
            float nextVal = ptr[index + 1];
            return curVal + (nextVal - curVal) * frac;
        }
    }
}
}

ui::action_transform_f const &ui::ease_in_transformer() {
    static action_transform_f const _transformer = [](float const pos) {
        return action_utils::_convert_value(action_utils::_ease_in_curve, pos);
    };

    action_utils::setup_curve();

    return _transformer;
}

ui::action_transform_f const &ui::ease_out_transformer() {
    static action_transform_f const _transformer = [](float const pos) {
        return action_utils::_convert_value(action_utils::_ease_out_curve, pos);
    };

    action_utils::setup_curve();

    return _transformer;
}

ui::action_transform_f const &ui::ease_in_out_transformer() {
    static action_transform_f const _transformer = [](float const pos) {
        return action_utils::_convert_value(action_utils::_ease_in_out_curve, pos);
    };

    action_utils::setup_curve();

    return _transformer;
}

#pragma mark - action::impl

struct ui::action::impl : public base::impl, public updatable_action::impl {
    void update(time_point_t const &time) override {
        if (update_handler && update_handler(time)) {
            if (finish_handler) {
                finish_handler();
            }
        }
    }

    void set_finish_handler(action_finish_f &&handler) override {
        finish_handler = std::move(handler);
    }

    weak<ui::node> target{nullptr};
    action_update_f update_handler;
    action_finish_f finish_handler;
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

ui::action_update_f const &ui::action::update_handler() const {
    return impl_ptr<impl>()->update_handler;
}

void ui::action::set_target(ui::node target) {
    impl_ptr<impl>()->target = target;
}

void ui::action::set_update_handler(action_update_f handler) {
    impl_ptr<impl>()->update_handler = std::move(handler);
}

ui::updatable_action ui::action::updatable() {
    return ui::updatable_action{impl_ptr<ui::updatable_action::impl>()};
}

#pragma mark - action::impl

struct ui::one_shot_action::impl : public action::impl {
    virtual void value_update(double const value) = 0;

    time_point_t start_time = std::chrono::system_clock::now();
    double duration = 0.3;
    action_transform_f value_transformer;
    action_completion_f completion_handler;
};

#pragma mark - one_shot_action

ui::one_shot_action::one_shot_action(std::nullptr_t) : super_class(nullptr) {
}

ui::one_shot_action::one_shot_action(std::shared_ptr<impl> &&impl) : super_class(std::move(impl)) {
    set_update_handler([weak_action = to_weak(*this)](time_point_t const &time) {
        if (auto action = weak_action.lock()) {
            auto impl_ptr = action.impl_ptr<one_shot_action::impl>();

            std::chrono::duration<double> const time_diff = time - impl_ptr->start_time;
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

            if (finished) {
                if (auto const &completion = impl_ptr->completion_handler) {
                    completion();
                }
            }

            return finished;
        }

        return true;
    });
}

std::chrono::time_point<std::chrono::system_clock> const &ui::one_shot_action::start_time() const {
    return impl_ptr<impl>()->start_time;
}

double ui::one_shot_action::duration() const {
    return impl_ptr<impl>()->duration;
}

ui::action_transform_f const &ui::one_shot_action::value_transformer() const {
    return impl_ptr<impl>()->value_transformer;
}

ui::action_completion_f const &ui::one_shot_action::completion_handler() const {
    return impl_ptr<impl>()->completion_handler;
}

void ui::one_shot_action::set_start_time(time_point_t time) {
    impl_ptr<impl>()->start_time = std::move(time);
}

void ui::one_shot_action::set_duration(double const &duration) {
    impl_ptr<impl>()->duration = duration;
}

void ui::one_shot_action::set_value_transformer(action_transform_f transformer) {
    impl_ptr<impl>()->value_transformer = std::move(transformer);
}

void ui::one_shot_action::set_completion_handler(action_completion_f handler) {
    impl_ptr<impl>()->completion_handler = std::move(handler);
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
