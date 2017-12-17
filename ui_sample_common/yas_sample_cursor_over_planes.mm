//
//  yas_sample_cursor_over_planes.mm
//

#include "yas_fast_each.h"
#include "yas_sample_cursor_over_planes.h"
#include "yas_ui_collider.h"

using namespace yas;

struct sample::cursor_over_planes::impl : base::impl {
    ui::node root_node;

    impl() {
        _setup_nodes();
    }

    void prepare(sample::cursor_over_planes &planes) {
        root_node.dispatch_method(ui::node::method::renderer_changed);
        _renderer_observer = root_node.subject().make_observer(
            ui::node::method::renderer_changed,
            [weak_touch_holder = to_weak(planes), event_observers = std::vector<base>{}](auto const &context) mutable {
                if (auto touch_holder = weak_touch_holder.lock()) {
                    auto impl = touch_holder.impl_ptr<cursor_over_planes::impl>();
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

        auto each = make_fast_each(count);
        while (yas_each_next(each)) {
            auto const &idx = yas_each_index(each);
            auto plane = ui::make_rect_plane(1);
            plane.data().set_rect_position({.origin = {-0.5f, -0.5f}, .size = {1.0f, 1.0f}}, 0);

            auto &node = plane.node();
            node.set_position({100.0f, 0.0f});
            node.set_scale({10.0f, 30.0f});
            node.set_color({.v = 0.3f});
            node.set_collider(ui::collider{ui::shape{ui::rect_shape{}}});

            ui::node handle_node;
            handle_node.add_sub_node(node);
            handle_node.set_angle({360.0f / count * idx});

            root_node.add_sub_node(handle_node);

            _nodes.emplace_back(node);
        }
    }

    static std::vector<base> _make_event_observers(std::vector<ui::node> const &nodes, ui::renderer &renderer) {
        std::vector<base> event_observers;
        event_observers.reserve(nodes.size());

        for (auto &node : nodes) {
            event_observers.emplace_back(renderer.event_manager().subject().make_observer(
                ui::event_manager::method::cursor_changed,
                [weak_node = to_weak(node),
                 prev_detected = std::make_shared<bool>(false)](auto const &context) {
                    ui::event const &event = context.value;
                    auto cursor_event = event.get<ui::cursor>();

                    if (auto node = weak_node.lock()) {
                        if (auto renderer = node.renderer()) {
                            auto is_detected = renderer.detector().detect(cursor_event.position(), node.collider());

                            auto make_color_action = [](ui::node &node, ui::color const &color) {
                                return ui::make_action(
                                    {.target = node, .begin_color = node.color(), .end_color = color});
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

        return event_observers;
    }

    std::vector<ui::node> _nodes;
    ui::node::observer_t _renderer_observer = nullptr;
};

sample::cursor_over_planes::cursor_over_planes() : base(std::make_shared<impl>()) {
    impl_ptr<impl>()->prepare(*this);
}

sample::cursor_over_planes::cursor_over_planes(std::nullptr_t) : base(nullptr) {
}

ui::node &sample::cursor_over_planes::node() {
    return impl_ptr<impl>()->root_node;
}
