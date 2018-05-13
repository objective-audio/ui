//
//  yas_ui_node_actions.mm
//

#include "yas_ui_node_actions.h"
#include "yas_stl_utils.h"
#include "yas_ui_angle.h"
#include "yas_ui_node.h"

using namespace yas;

#pragma mark - translate_action

ui::continuous_action ui::make_action(translate_action::args args) {
    auto target = args.target;
    ui::continuous_action action{std::move(args.continuous_action)};
    action.set_target(target);

    action.set_value_updater([args = std::move(args), weak_action = to_weak(action)](double const value) {
        if (auto action = weak_action.lock()) {
            if (auto target = args.target.lock()) {
                target.set_position(
                    {.v = (args.end_position.v - args.begin_position.v) * (float)value + args.begin_position.v});
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
                auto begin_angle = args.begin_angle;

                if (args.is_shortest) {
                    begin_angle = begin_angle.shortest_from(end_angle);
                }

                target.set_angle({(end_angle - begin_angle) * static_cast<float>(value) + begin_angle});
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
                target.set_scale({.v = (args.end_scale.v - args.begin_scale.v) * (float)value + args.begin_scale.v});
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
                target.set_color({.v = (args.end_color.v - args.begin_color.v) * (float)value + args.begin_color.v});
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
                target.set_alpha((args.end_alpha - args.begin_alpha) * (float)value + args.begin_alpha);
            }
        }
    });

    return action;
}
