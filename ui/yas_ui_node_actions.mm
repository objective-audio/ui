//
//  yas_ui_node_actions.mm
//

#include "yas_stl_utils.h"
#include "yas_ui_node.h"
#include "yas_ui_node_actions.h"

using namespace yas;

#pragma mark - translate_action

ui::continuous_action ui::make_action(translate_action::args args) {
    auto target = args.target;
    ui::continuous_action action{std::move(args.continuous_action)};
    action.set_target(target);

    action.set_value_updater([args = std::move(args), weak_action = to_weak(action)](double const value) {
        if (auto action = weak_action.lock()) {
            if (auto target = args.target.lock()) {
                target.set_position((args.end_position.v - args.start_position.v) * (float)value +
                                    args.start_position.v);
            }
        }
    });

    return action;
}

#pragma mark - rotate_action

ui::continuous_action ui::make_action(rotate_action::args args) {
    auto target = args.target;
    ui::continuous_action action{std::move(args.continuous_action)};
    action.set_target(target);

    action.set_value_updater([args = std::move(args), weak_action = to_weak(action)](double const value) {
        if (auto action = weak_action.lock()) {
            if (auto target = args.target.lock()) {
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

ui::continuous_action ui::make_action(ui::scale_action::args args) {
    auto target = args.target;
    ui::continuous_action action{std::move(args.continuous_action)};
    action.set_target(target);

    action.set_value_updater([args = std::move(args), weak_action = to_weak(action)](double const value) {
        if (auto action = weak_action.lock()) {
            if (auto target = args.target.lock()) {
                target.set_scale({.v = (args.end_scale.v - args.start_scale.v) * (float)value + args.start_scale.v});
            }
        }
    });

    return action;
}

#pragma mark - color_action

ui::continuous_action ui::make_action(ui::color_action::args args) {
    auto target = args.target;
    ui::continuous_action action{std::move(args.continuous_action)};
    action.set_target(target);

    action.set_value_updater([args = std::move(args), weak_action = to_weak(action)](double const value) {
        if (auto action = weak_action.lock()) {
            if (auto target = args.target.lock()) {
                target.set_color((args.end_color.v - args.start_color.v) * (float)value + args.start_color.v);
            }
        }
    });

    return action;
}

#pragma mark - alpha_action

ui::continuous_action ui::make_action(ui::alpha_action::args args) {
    auto target = args.target;
    ui::continuous_action action{std::move(args.continuous_action)};
    action.set_target(target);

    action.set_value_updater([args = std::move(args), weak_action = to_weak(action)](double const value) {
        if (auto action = weak_action.lock()) {
            if (auto target = args.target.lock()) {
                target.set_alpha((args.end_alpha - args.start_alpha) * (float)value + args.start_alpha);
            }
        }
    });

    return action;
}