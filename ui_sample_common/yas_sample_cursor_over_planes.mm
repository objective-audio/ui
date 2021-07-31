//
//  yas_sample_cursor_over_planes.mm
//

#include "yas_sample_cursor_over_planes.h"
#include <cpp_utils/yas_fast_each.h>
#include <ui/yas_ui_collider.h>

using namespace yas;
using namespace yas::ui;

namespace yas::sample::cursor_over_planes_utils {
static observing::cancellable_ptr _observe_events(std::vector<std::shared_ptr<node>> const &nodes,
                                                  std::shared_ptr<ui::event_manager> const &event_manager,
                                                  std::shared_ptr<ui::action_manager> const &action_manager,
                                                  std::shared_ptr<ui::detector> const &detector) {
    auto pool = observing::canceller_pool::make_shared();

    for (auto &node : nodes) {
        auto const group = action_group::make_shared();

        event_manager
            ->observe([group, weak_node = to_weak(node), weak_action_manager = to_weak(action_manager),
                       weak_detector = to_weak(detector),
                       prev_detected = std::make_shared<bool>(false)](std::shared_ptr<event> const &event) {
                if (event->type() == event_type::cursor) {
                    auto const &cursor_event = event->get<ui::cursor>();

                    auto const node = weak_node.lock();
                    auto const action_manager = weak_action_manager.lock();
                    auto const detector = weak_detector.lock();
                    if (node && action_manager && detector) {
                        auto is_detected = detector->detect(cursor_event.position(), node->collider());

                        auto make_color_action = [&group](std::shared_ptr<ui::node> const &node, color const &color) {
                            return make_action(
                                {.group = group, .target = node, .begin_color = node->color(), .end_color = color});
                        };

                        if (is_detected && !*prev_detected) {
                            action_manager->erase_action(group);
                            action_manager->insert_action(make_color_action(node, {1.0f, 0.6f, 0.0f}));
                        } else if (!is_detected && *prev_detected) {
                            action_manager->erase_action(group);
                            action_manager->insert_action(make_color_action(node, {0.3f, 0.3f, 0.3f}));
                        }

                        *prev_detected = is_detected;
                    }
                }
            })
            .end()
            ->add_to(*pool);
    }

    return pool;
}
}

sample::cursor_over_planes::cursor_over_planes(std::shared_ptr<ui::event_manager> const &event_manager,
                                               std::shared_ptr<ui::action_manager> const &action_manager,
                                               std::shared_ptr<ui::detector> const &detector) {
    this->_setup_nodes();

    cursor_over_planes_utils::_observe_events(this->_nodes, event_manager, action_manager, detector)
        ->set_to(this->_event_canceller);
}

std::shared_ptr<node> const &sample::cursor_over_planes::node() {
    return this->root_node;
}

void sample::cursor_over_planes::_setup_nodes() {
    auto const count = 16;
    this->_nodes.reserve(count);

    auto each = make_fast_each(count);
    while (yas_each_next(each)) {
        auto const &idx = yas_each_index(each);
        auto plane = rect_plane::make_shared(1);
        plane->data()->set_rect_position({.origin = {-0.5f, -0.5f}, .size = {1.0f, 1.0f}}, 0);

        auto const &node = plane->node();
        node->set_position({100.0f, 0.0f});
        node->set_scale({10.0f, 30.0f});
        node->set_color({.v = 0.3f});
        node->set_collider(collider::make_shared(shape::make_shared(rect_shape{})));

        auto handle_node = node::make_shared();
        handle_node->add_sub_node(node);
        handle_node->set_angle({360.0f / count * idx});

        root_node->add_sub_node(handle_node);

        this->_nodes.emplace_back(node);
    }
}

sample::cursor_over_planes_ptr sample::cursor_over_planes::make_shared(
    std::shared_ptr<ui::event_manager> const &event_manager, std::shared_ptr<ui::action_manager> const &action_manager,
    std::shared_ptr<ui::detector> const &detector) {
    return std::shared_ptr<cursor_over_planes>(new cursor_over_planes{event_manager, action_manager, detector});
}
