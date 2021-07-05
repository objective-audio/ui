//
//  yas_sample_cursor.mm
//

#include "yas_sample_cursor.h"
#include <cpp_utils/yas_fast_each.h>

using namespace yas;
using namespace yas::ui;

#pragma mark -

namespace yas::sample::cursor_utils {
static std::shared_ptr<action> _make_rotate_action(std::shared_ptr<node> const &target) {
    auto rotate_action = make_action({.target = target, .end_angle = -360.0f, .duration = 2.0f, .loop_count = 0});

    auto scale_action =
        make_action({.target = target,
                     .begin_scale = {.v = 10.0f},
                     .end_scale = {.v = 15.0f},
                     .duration = 5.0f,
                     .loop_count = 0,
                     .value_transformer = ui::connect({ping_pong_transformer(), ease_in_out_sine_transformer()})});

    return parallel_action::make_shared({.actions = {std::move(rotate_action), std::move(scale_action)}})->raw_action();
}

static observing::endable _observe_event(std::shared_ptr<node> const &node,
                                         std::shared_ptr<event_manager> const &event_manager,
                                         std::shared_ptr<action_manager> const &action_manager) {
    return event_manager->observe([weak_node = to_weak(node), weak_action_manager = to_weak(action_manager),
                                   weak_action = std::weak_ptr<action>{}](std::shared_ptr<event> const &event) mutable {
        if (event->type() == event_type::cursor) {
            if (auto node = weak_node.lock()) {
                auto const &value = event->get<ui::cursor>();

                node->set_position(node->parent()->convert_position(value.position()));

                if (auto const action_manager = weak_action_manager.lock()) {
                    for (auto child_node : node->children()) {
                        auto make_fade_action = [](std::shared_ptr<ui::node> const &node, float const alpha) {
                            return make_action(
                                {.target = node, .begin_alpha = node->alpha(), .end_alpha = alpha, .duration = 0.5});
                        };

                        switch (event->phase()) {
                            case event_phase::began: {
                                if (auto prev_action = weak_action.lock()) {
                                    action_manager->erase_action(prev_action);
                                }

                                auto action = make_fade_action(child_node, 1.0f);
                                action_manager->insert_action(action);
                                weak_action = action;
                            } break;

                            case event_phase::ended: {
                                if (auto prev_action = weak_action.lock()) {
                                    action_manager->erase_action(prev_action);
                                }

                                auto action = make_fade_action(child_node, 0.0f);
                                action_manager->insert_action(action);
                                weak_action = action;
                            } break;

                            default:
                                break;
                        }
                    }
                }
            }
        }
    });
}
}

sample::cursor::cursor(std::shared_ptr<ui::event_manager> const &event_manager,
                       std::shared_ptr<ui::action_manager> const &action_manager) {
    this->_setup_node();

    cursor_utils::_observe_event(this->_node, event_manager, action_manager).end()->set_to(this->_event_canceller);
    action_manager->insert_action(cursor_utils::_make_rotate_action(this->_node));
}

std::shared_ptr<node> const &sample::cursor::node() {
    return this->_node;
}

void sample::cursor::_setup_node() {
    auto const count = 5;
    auto const angle_dif = 360.0f / count;
    auto plane = rect_plane::make_shared(count);

    region region{.origin = {-0.5f, -0.5f}, .size = {1.0f, 1.0f}};
    auto trans_matrix = matrix::translation(0.0f, 1.6f);

    auto each = make_fast_each(count);
    while (yas_each_next(each)) {
        auto const &idx = yas_each_index(each);
        plane->data()->set_rect_position(region, idx, matrix::rotation(angle_dif * idx) * trans_matrix);
    }

    plane->node()->set_color({.red = 0.0f, .green = 0.6f, .blue = 1.0f});
    plane->node()->set_alpha(0.0f);
    this->_node->add_sub_node(plane->node());
}

sample::cursor_ptr sample::cursor::make_shared(std::shared_ptr<ui::event_manager> const &event_manager,
                                               std::shared_ptr<ui::action_manager> const &action_manager) {
    return std::shared_ptr<cursor>(new cursor{event_manager, action_manager});
}
