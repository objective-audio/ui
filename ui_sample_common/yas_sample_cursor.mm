//
//  yas_sample_cursor.mm
//

#include "yas_sample_cursor.h"
#include <cpp_utils/yas_fast_each.h>

using namespace yas;

#pragma mark -

namespace yas::sample::cursor_utils {
static std::shared_ptr<ui::parallel_action> _make_rotate_action(ui::node_ptr const &target) {
    auto rotate_action = ui::make_action(
        {.target = target, .end_angle = -360.0f, .continuous_action = {.duration = 2.0f, .loop_count = 0}});

    auto scale_action = ui::make_action({.target = target,
                                         .begin_scale = {.v = 10.0f},
                                         .end_scale = {.v = 15.0f},
                                         .continuous_action = {.duration = 5.0f, .loop_count = 0}});
    scale_action->set_value_transformer(ui::connect({ui::ping_pong_transformer(), ui::ease_in_out_sine_transformer()}));

    return ui::parallel_action::make_shared({.actions = {std::move(rotate_action), std::move(scale_action)}});
}

static observing::canceller_ptr _observe_event(ui::node_ptr const &node, ui::renderer_ptr const &renderer) {
    return renderer->event_manager()->observe(
        [weak_node = to_weak(node), weak_action = std::weak_ptr<ui::action>{}](auto const &context) mutable {
            if (context.method == ui::event_manager::method::cursor_changed) {
                ui::event_ptr const &event = context.event;
                if (auto node = weak_node.lock()) {
                    auto const &value = event->get<ui::cursor>();

                    node->position()->set_value(node->parent()->convert_position(value.position()));

                    if (auto renderer = node->renderer()) {
                        for (auto child_node : node->children()) {
                            auto make_fade_action = [](ui::node_ptr const &node, float const alpha) {
                                return ui::make_action({.target = node,
                                                        .begin_alpha = node->alpha()->value(),
                                                        .end_alpha = alpha,
                                                        .continuous_action = {.duration = 0.5}});
                            };

                            switch (event->phase()) {
                                case ui::event_phase::began: {
                                    if (auto prev_action = weak_action.lock()) {
                                        renderer->erase_action(prev_action);
                                    }

                                    auto action = make_fade_action(child_node, 1.0f);
                                    renderer->insert_action(action);
                                    weak_action = action;
                                } break;

                                case ui::event_phase::ended: {
                                    if (auto prev_action = weak_action.lock()) {
                                        renderer->erase_action(prev_action);
                                    }

                                    auto action = make_fade_action(child_node, 0.0f);
                                    renderer->insert_action(action);
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

sample::cursor::cursor() {
    this->_setup_node();

    this->_node
        ->observe_renderer(
            [this, event_canceller = observing::canceller_ptr{nullptr}](ui::renderer_ptr const &renderer) mutable {
                if (renderer) {
                    event_canceller = cursor_utils::_observe_event(this->_node, renderer);
                    renderer->insert_action(cursor_utils::_make_rotate_action(this->_node));
                } else {
                    event_canceller = nullptr;
                }
            },
            false)
        ->set_to(this->_renderer_canceller);
}

ui::node_ptr const &sample::cursor::node() {
    return this->_node;
}

void sample::cursor::_setup_node() {
    auto const count = 5;
    auto const angle_dif = 360.0f / count;
    auto plane = ui::rect_plane::make_shared(count);

    ui::region region{.origin = {-0.5f, -0.5f}, .size = {1.0f, 1.0f}};
    auto trans_matrix = ui::matrix::translation(0.0f, 1.6f);

    auto each = make_fast_each(count);
    while (yas_each_next(each)) {
        auto const &idx = yas_each_index(each);
        plane->data()->set_rect_position(region, idx, ui::matrix::rotation(angle_dif * idx) * trans_matrix);
    }

    plane->node()->set_color({.red = 0.0f, .green = 0.6f, .blue = 1.0f});
    plane->node()->alpha()->set_value(0.0f);
    this->_node->add_sub_node(plane->node());
}

sample::cursor_ptr sample::cursor::make_shared() {
    return std::shared_ptr<cursor>(new cursor{});
}
