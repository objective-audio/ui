//
//  yas_sample_cursor_over_planes.mm
//

#include "yas_sample_cursor_over_planes.h"
#include <cpp-utils/fast_each.h>
#include <ui/collider/yas_ui_collider.h>

using namespace yas;
using namespace yas::ui;

sample::cursor_over_planes::cursor_over_planes(std::shared_ptr<ui::standard> const &standard) {
    this->_setup_nodes();

    for (auto const &node : this->_nodes) {
        auto const group = action_group::make_shared();
        auto const cursor_tracker = ui::cursor_tracker::make_shared(standard, node);
        this->_trackers.emplace_back(cursor_tracker);

        cursor_tracker
            ->observe([group, weak_node = to_weak(node),
                       weak_action_manager = to_weak(standard->action_manager())](auto const &context) {
                auto const action_manager = weak_action_manager.lock();
                auto const node = weak_node.lock();

                if (action_manager && node) {
                    auto make_color_action = [&group](std::shared_ptr<ui::node> const &node, rgb_color const &color) {
                        return make_action(
                            {.group = group, .target = node, .begin_color = node->rgb_color(), .end_color = color});
                    };

                    switch (context.phase) {
                        case cursor_tracker_phase::entered: {
                            action_manager->erase_action(group);
                            action_manager->insert_action(make_color_action(node, {1.0f, 0.6f, 0.0f}));
                        } break;
                        case cursor_tracker_phase::leaved: {
                            action_manager->erase_action(group);
                            action_manager->insert_action(make_color_action(node, {0.3f, 0.3f, 0.3f}));
                        } break;
                        case cursor_tracker_phase::moved:
                            break;
                    }
                }
            })
            .end()
            ->add_to(this->_pool);
    }
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
        node->set_rgb_color({.v = 0.3f});
        node->set_colliders({collider::make_shared(shape::make_shared(rect_shape{}))});

        auto handle_node = node::make_shared();
        handle_node->add_sub_node(node);
        handle_node->set_angle({360.0f / count * idx});

        root_node->add_sub_node(handle_node);

        this->_nodes.emplace_back(node);
    }
}

sample::cursor_over_planes_ptr sample::cursor_over_planes::make_shared(std::shared_ptr<ui::standard> const &standard) {
    return std::shared_ptr<cursor_over_planes>(new cursor_over_planes{standard});
}
