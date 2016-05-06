//
//  yas_sample_cursor_over_node.mm
//

#include "yas_each_index.h"
#include "yas_sample_cursor_over_node.h"
#include "yas_ui_collider.h"

using namespace yas;

struct sample::cursor_over_node::impl : base::impl {
    ui::node root_node;

    impl() {
        _setup_nodes();
    }

    void setup_renderer_observer() {
        root_node.dispatch_method(ui::node_method::renderer_changed);
        _renderer_observer = root_node.subject().make_observer(
            ui::node_method::renderer_changed,
            [weak_touch_holder = to_weak(cast<cursor_over_node>()),
             event_observers = std::vector<base>{}](auto const &context) mutable {
                if (auto touch_holder = weak_touch_holder.lock()) {
                    auto impl = touch_holder.impl_ptr<cursor_over_node::impl>();
                    auto &node = context.value;
                    if (auto renderer = node.renderer()) {
                        event_observers = _make_event_observers(impl->_nodes, renderer);
                    } else {
                        event_observers.clear();
                    }
                }
            });
    }

   private:
    void _setup_nodes() {
        auto const count = 16;
        _nodes.reserve(count);

        for (auto const &idx : make_each(count)) {
            auto sq_node = ui::make_square_node(1);
            sq_node.square_mesh_data().set_square_position({-0.5f, -0.5f, 1.0f, 1.0f}, 0);

            auto &node = sq_node.node();
            node.set_position({100.0f, 0.0f});
            node.set_scale({10.0f, 30.0f});
            node.set_color(0.3f);
            node.set_collider({{.shape = ui::collider_shape::square}});

            ui::node handle_node;
            handle_node.add_sub_node(node);
            handle_node.set_angle(360.0f / count * idx);

            root_node.add_sub_node(handle_node);

            _nodes.emplace_back(node);
        }
    }

    static std::vector<base> _make_event_observers(std::vector<ui::node> const &nodes, ui::renderer &renderer) {
        std::vector<base> event_observers;
        event_observers.reserve(nodes.size());

        for (auto &node : nodes) {
            event_observers.emplace_back(renderer.event_manager().subject().make_observer(
                ui::event_method::cursor_changed,
                [weak_node = to_weak(node),
                 prev_detected = std::move(std::make_shared<bool>(false))](auto const &context) {
                    ui::event const &event = context.value;
                    auto cursor_event = event.get<ui::cursor>();

                    if (auto node = weak_node.lock()) {
                        if (auto renderer = node.renderer()) {
                            auto is_detected =
                                renderer.collision_detector().detect(cursor_event.position(), node.collider());

                            auto make_color_action = [](ui::node &node, ui::color const &color) {
                                auto action = ui::make_action({.start_color = node.color(), .end_color = color});
                                action.set_target(node);
                                return action;
                            };

                            if (is_detected && !*prev_detected) {
                                renderer.erase_action(node);
                                renderer.insert_action(make_color_action(node, {1.0f, 0.6f, 0.0f}));
                            } else if (!is_detected && *prev_detected) {
                                renderer.erase_action(node);
                                renderer.insert_action(make_color_action(node, {0.3f, 0.3f, 0.3f}));
                            }

                            *prev_detected = is_detected;
                        }
                    }
                }));
        }

        return std::move(event_observers);
    }

    std::vector<ui::node> _nodes;
    base _renderer_observer = nullptr;
};

sample::cursor_over_node::cursor_over_node() : base(std::make_shared<impl>()) {
    impl_ptr<impl>()->setup_renderer_observer();
}

sample::cursor_over_node::cursor_over_node(std::nullptr_t) : base(nullptr) {
}

ui::node &sample::cursor_over_node::node() {
    return impl_ptr<impl>()->root_node;
}
