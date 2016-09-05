//
//  yas_ui_layout_actions.cpp
//

#include "yas_ui_layout_actions.h"

using namespace yas;

ui::continuous_action ui::make_action(layout_action::args args) {
    auto target = args.target;
    ui::continuous_action action{std::move(args.continuous_action)};
    action.set_target(target);

    action.set_value_updater([args = std::move(args), weak_action = to_weak(action)](double const value) {
        if (auto action = weak_action.lock()) {
            if (auto target = args.target.lock()) {
                target.set_value((args.end_value - args.start_value) * (float)value + args.start_value);
            }
        }
    });

    return action;
}

ui::continuous_action ui::make_action(layout_point_action::args args) {
    auto target = args.target;
    ui::continuous_action action{std::move(args.continuous_action)};
    action.set_target(target);

    action.set_value_updater([args = std::move(args), weak_action = to_weak(action)](double const value) {
        if (auto action = weak_action.lock()) {
            if (auto target = args.target.lock()) {
                target.set_point((args.end_point.v - args.start_point.v) * (float)value + args.start_point.v);
            }
        }
    });

    return action;
}

ui::continuous_action ui::make_action(layout_range_action::args args) {
    auto target = args.target;
    ui::continuous_action action{std::move(args.continuous_action)};
    action.set_target(target);

    action.set_value_updater([args = std::move(args), weak_action = to_weak(action)](double const value) {
        if (auto action = weak_action.lock()) {
            if (auto target = args.target.lock()) {
                target.set_range({.v = (args.end_range.v - args.start_range.v) * (float)value + args.start_range.v});
            }
        }
    });

    return action;
}

ui::continuous_action ui::make_action(layout_rect_action::args args) {
    auto target = args.target;
    ui::continuous_action action{std::move(args.continuous_action)};
    action.set_target(target);

    action.set_value_updater([args = std::move(args), weak_action = to_weak(action)](double const value) {
        if (auto action = weak_action.lock()) {
            if (auto target = args.target.lock()) {
                auto const origin =
                    (args.end_region.origin.v - args.start_region.origin.v) * (float)value + args.start_region.origin.v;
                auto const size =
                    (args.end_region.size.v - args.start_region.size.v) * (float)value + args.start_region.size.v;
                target.set_region({.origin = origin, .size = {.v = size}});
            }
        }
    });

    return action;
}
