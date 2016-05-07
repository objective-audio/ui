//
//  yas_sample_cursor_node.mm
//

#include "yas_each_index.h"
#include "yas_sample_cursor_node.h"

using namespace yas;

#pragma mark -

struct sample::cursor_node::impl : base::impl {
    ui::node node;

    impl() {
        _setup_node();
    }

    void setup_renderer_observer() {
        node.dispatch_method(ui::node_method::renderer_changed);
        _renderer_observer = node.subject().make_observer(
            ui::node_method::renderer_changed,
            [weak_cursor_node = to_weak(cast<cursor_node>()),
             event_observer = base{nullptr}](auto const &context) mutable {
                if (auto cursor_node = weak_cursor_node.lock()) {
                    auto impl = cursor_node.impl_ptr<cursor_node::impl>();
                    auto node = context.value;
                    if (auto renderer = node.renderer()) {
                        event_observer = _make_event_observer(node, renderer);
                        renderer.insert_action(_make_rotate_action(node));
                    } else {
                        event_observer = nullptr;
                        renderer.erase_action(node);
                    }
                }
            });
    }

   private:
    void _setup_node() {
        auto const count = 5;
        auto const angle_dif = 360.0f / count;
        auto mesh_node = ui::make_square_node(count);

        ui::float_region region{-0.5f, -0.5f, 1.0f, 1.0f};
        auto trans_matrix = ui::matrix::translation(0.0f, 1.6f);
        for (auto const &idx : make_each(count)) {
            mesh_node.square_mesh_data().set_square_position(region, idx,
                                                             ui::matrix::rotation(angle_dif * idx) * trans_matrix);
        }

        mesh_node.node().set_color(0.0f);
        mesh_node.node().set_alpha(0.0f);
        node.push_back_sub_node(mesh_node.node());
    }

    static ui::action _make_rotate_action(ui::node &target) {
        auto rotate_action =
            ui::make_action({.end_angle = -360.0f, .continuous_action = {.duration = 2.0f, .loop_count = 0}});
        rotate_action.set_target(target);

        auto scale_action = ui::make_action(
            {.start_scale = 10.0f, .end_scale = 15.0f, .continuous_action = {.duration = 5.0f, .loop_count = 0}});
        scale_action.set_value_transformer(ui::connect({ui::ping_pong_transformer(), ui::ease_in_out_transformer()}));
        scale_action.set_target(target);

        ui::parallel_action action;
        action.insert_action(std::move(rotate_action));
        action.insert_action(std::move(scale_action));
        return action;
    }

    static base _make_event_observer(ui::node &node, ui::renderer &renderer) {
        return renderer.event_manager().subject().make_observer(
            ui::event_method::cursor_changed,
            [weak_node = to_weak(node), weak_action = weak<ui::action>{}](auto const &context) mutable {
                if (auto node = weak_node.lock()) {
                    ui::event const &event = context.value;
                    auto const &value = event.get<ui::cursor>();

                    node.set_position(node.parent().convert_position(value.position()));

                    if (auto renderer = node.renderer()) {
                        for (auto child_node : node.children()) {
                            auto make_fade_action = [](ui::node &node, simd::float3 const &color, float const alpha) {
                                double const duration = 0.5;

                                ui::parallel_action action;

                                auto color_action = ui::make_action({.start_color = node.color(),
                                                                     .end_color = color,
                                                                     .continuous_action = {.duration = duration}});
                                color_action.set_target(node);
                                action.insert_action(std::move(color_action));

                                auto alpha_action = ui::make_action({.start_alpha = node.alpha(),
                                                                     .end_alpha = alpha,
                                                                     .continuous_action = {.duration = duration}});
                                alpha_action.set_target(node);
                                action.insert_action(std::move(alpha_action));

                                action.set_target(node);

                                return action;
                            };

                            switch (event.phase()) {
                                case ui::event_phase::began: {
                                    if (auto prev_action = weak_action.lock()) {
                                        renderer.erase_action(prev_action);
                                    }

                                    auto action = make_fade_action(child_node, simd::float3{0.0f, 0.6f, 1.0f}, 1.0f);
                                    renderer.insert_action(action);
                                    weak_action = action;
                                } break;

                                case ui::event_phase::ended: {
                                    if (auto prev_action = weak_action.lock()) {
                                        renderer.erase_action(prev_action);
                                    }

                                    auto action = make_fade_action(child_node, simd::float3{0.0f}, 0.0f);
                                    renderer.insert_action(action);
                                    weak_action = action;
                                } break;

                                default:
                                    break;
                            }
                            break;
                        }
                    }
                }
            });
    }

    base _renderer_observer = nullptr;
};

sample::cursor_node::cursor_node() : base(std::make_shared<impl>()) {
    impl_ptr<impl>()->setup_renderer_observer();
}

sample::cursor_node::cursor_node(std::nullptr_t) : base(nullptr) {
}

ui::node &sample::cursor_node::node() {
    return impl_ptr<impl>()->node;
}
