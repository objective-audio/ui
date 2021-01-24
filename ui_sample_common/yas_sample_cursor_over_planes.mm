//
//  yas_sample_cursor_over_planes.mm
//

#include "yas_sample_cursor_over_planes.h"
#include <cpp_utils/yas_fast_each.h>
#include <ui/yas_ui_collider.h>

using namespace yas;

namespace yas::sample::cursor_over_planes_utils {
static std::vector<observing::canceller_ptr> _observe_events(std::vector<ui::node_ptr> const &nodes,
                                                             ui::renderer_ptr const &renderer) {
    std::vector<observing::canceller_ptr> event_cancellers;
    event_cancellers.reserve(nodes.size());

    for (auto &node : nodes) {
        event_cancellers.emplace_back(renderer->event_manager()->observe(
            [weak_node = to_weak(node), prev_detected = std::make_shared<bool>(false)](auto const &context) {
                if (context.method == ui::event_manager::method::cursor_changed) {
                    ui::event_ptr const &event = context.event;
                    auto const &cursor_event = event->get<ui::cursor>();

                    if (auto node = weak_node.lock()) {
                        if (auto renderer = node->renderer()) {
                            auto is_detected =
                                renderer->detector()->detect(cursor_event.position(), node->collider()->value());

                            auto make_color_action = [](ui::node_ptr const &node, ui::color const &color) {
                                return ui::make_action(
                                    {.target = node, .begin_color = node->color()->value(), .end_color = color});
                            };

                            if (is_detected && !*prev_detected) {
                                renderer->erase_action(node);
                                renderer->insert_action(make_color_action(node, {1.0f, 0.6f, 0.0f}));
                            } else if (!is_detected && *prev_detected) {
                                renderer->erase_action(node);
                                renderer->insert_action(make_color_action(node, {0.3f, 0.3f, 0.3f}));
                            }

                            *prev_detected = is_detected;
                        }
                    }
                }
            }));
    }

    return event_cancellers;
}
}

sample::cursor_over_planes::cursor_over_planes() {
    this->_setup_nodes();
}

ui::node_ptr const &sample::cursor_over_planes::node() {
    return this->root_node;
}

void sample::cursor_over_planes::_prepare(cursor_over_planes_ptr const &shared) {
    this->_renderer_observer =
        root_node->chain_renderer()
            .perform([weak_planes = to_weak(shared), event_observers = std::vector<observing::canceller_ptr>{}](
                         ui::renderer_ptr const &value) mutable {
                if (auto planes = weak_planes.lock()) {
                    if (value) {
                        event_observers = cursor_over_planes_utils::_observe_events(planes->_nodes, value);
                    } else {
                        event_observers.clear();
                    }
                }
            })
            .end();
}

void sample::cursor_over_planes::_setup_nodes() {
    auto const count = 16;
    this->_nodes.reserve(count);

    auto each = make_fast_each(count);
    while (yas_each_next(each)) {
        auto const &idx = yas_each_index(each);
        auto plane = ui::rect_plane::make_shared(1);
        plane->data()->set_rect_position({.origin = {-0.5f, -0.5f}, .size = {1.0f, 1.0f}}, 0);

        auto const &node = plane->node();
        node->position()->set_value({100.0f, 0.0f});
        node->scale()->set_value({10.0f, 30.0f});
        node->color()->set_value({.v = 0.3f});
        node->collider()->set_value(ui::collider::make_shared(ui::shape::make_shared(ui::rect_shape{})));

        auto handle_node = ui::node::make_shared();
        handle_node->add_sub_node(node);
        handle_node->angle()->set_value({360.0f / count * idx});

        root_node->add_sub_node(handle_node);

        this->_nodes.emplace_back(node);
    }
}

sample::cursor_over_planes_ptr sample::cursor_over_planes::make_shared() {
    auto shared = std::shared_ptr<cursor_over_planes>(new cursor_over_planes{});
    shared->_prepare(shared);
    return shared;
}
