//
//  yas_ui_node_actions.mm
//

#include "yas_ui_node_actions.h"
#include <cpp_utils/yas_stl_utils.h>
#include "yas_ui_angle.h"

using namespace yas;
using namespace yas::ui;

#pragma mark - translate_action

std::shared_ptr<action> ui::make_action(translate_action::args args) {
    auto continuous_args = action::continuous_args{.duration = std::move(args.duration),
                                                   .loop_count = std::move(args.loop_count),
                                                   .value_transformer = std::move(args.value_transformer),
                                                   .target = args.target,
                                                   .begin_time = std::move(args.begin_time),
                                                   .delay = std::move(args.delay),
                                                   .completion = std::move(args.completion)};

    continuous_args.value_updater = [args = std::move(args)](double const value) {
        if (auto target = args.target.lock()) {
            target->set_position(
                {.v = (args.end_position.v - args.begin_position.v) * (float)value + args.begin_position.v});
        }
    };

    return action::make_continuous(std::move(continuous_args));
}

#pragma mark - rotate_action

std::shared_ptr<action> ui::make_action(rotate_action::args args) {
    auto continuous_args = action::continuous_args{.duration = std::move(args.duration),
                                                   .loop_count = std::move(args.loop_count),
                                                   .value_transformer = std::move(args.value_transformer),
                                                   .target = args.target,
                                                   .begin_time = std::move(args.begin_time),
                                                   .delay = std::move(args.delay),
                                                   .completion = std::move(args.completion)};

    continuous_args.value_updater = [args = std::move(args)](double const value) {
        if (auto target = args.target.lock()) {
            auto const end_angle = args.end_angle;
            auto begin_angle = args.begin_angle;

            if (args.is_shortest) {
                begin_angle = begin_angle.shortest_from(end_angle);
            }

            target->set_angle({(end_angle - begin_angle) * static_cast<float>(value) + begin_angle});
        }
    };

    return action::make_continuous(std::move(continuous_args));
    ;
}

#pragma mark - scale_action

std::shared_ptr<action> ui::make_action(scale_action::args args) {
    auto continuous_args = action::continuous_args{.duration = std::move(args.duration),
                                                   .loop_count = std::move(args.loop_count),
                                                   .value_transformer = std::move(args.value_transformer),
                                                   .target = args.target,
                                                   .begin_time = std::move(args.begin_time),
                                                   .delay = std::move(args.delay),
                                                   .completion = std::move(args.completion)};

    continuous_args.value_updater = [args = std::move(args)](double const value) {
        if (auto target = args.target.lock()) {
            target->set_scale({.v = (args.end_scale.v - args.begin_scale.v) * (float)value + args.begin_scale.v});
        }
    };

    return action::make_continuous(std::move(continuous_args));
}

#pragma mark - color_action

std::shared_ptr<action> ui::make_action(color_action::args args) {
    auto continuous_args = action::continuous_args{.duration = std::move(args.duration),
                                                   .loop_count = std::move(args.loop_count),
                                                   .value_transformer = std::move(args.value_transformer),
                                                   .target = args.target,
                                                   .begin_time = std::move(args.begin_time),
                                                   .delay = std::move(args.delay),
                                                   .completion = std::move(args.completion)};

    continuous_args.value_updater = [args = std::move(args)](double const value) {
        if (auto target = args.target.lock()) {
            target->set_color({.v = (args.end_color.v - args.begin_color.v) * (float)value + args.begin_color.v});
        }
    };

    return action::make_continuous(std::move(continuous_args));
}

#pragma mark - alpha_action

std::shared_ptr<action> ui::make_action(alpha_action::args args) {
    auto continuous_args = action::continuous_args{.duration = std::move(args.duration),
                                                   .loop_count = std::move(args.loop_count),
                                                   .value_transformer = std::move(args.value_transformer),
                                                   .target = args.target,
                                                   .begin_time = std::move(args.begin_time),
                                                   .delay = std::move(args.delay),
                                                   .completion = std::move(args.completion)};

    continuous_args.value_updater = [args = std::move(args)](double const value) {
        if (auto target = args.target.lock()) {
            target->set_alpha((args.end_alpha - args.begin_alpha) * (float)value + args.begin_alpha);
        }
    };

    return action::make_continuous(std::move(continuous_args));
}
