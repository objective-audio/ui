//
//  yas_sample_cursor.mm
//

#include "yas_sample_cursor.h"
#include <cpp_utils/yas_fast_each.h>

using namespace yas;

#pragma mark -

struct sample::cursor::impl : base::impl {
    ui::node node;

    impl() {
        this->_setup_node();
    }

    void prepare(sample::cursor &cursor) {
        this->_renderer_observer = node.chain_renderer()
                                       .perform([weak_node = to_weak(this->node), weak_cursor = to_weak(cursor),
                                                 event_observer = base{nullptr}](ui::renderer const &value) mutable {
                                           if (auto cursor = weak_cursor.lock()) {
                                               auto impl = cursor.impl_ptr<sample::cursor::impl>();
                                               auto node = weak_node.lock();
                                               if (ui::renderer renderer = value) {
                                                   event_observer = _make_event_observer(node, renderer);
                                                   renderer.insert_action(_make_rotate_action(node));
                                               } else {
                                                   event_observer = nullptr;
                                                   renderer.erase_action(node);
                                               }
                                           }
                                       })
                                       .end();
    }

   private:
    void _setup_node() {
        auto const count = 5;
        auto const angle_dif = 360.0f / count;
        ui::rect_plane mesh_node{count};

        ui::region region{.origin = {-0.5f, -0.5f}, .size = {1.0f, 1.0f}};
        auto trans_matrix = ui::matrix::translation(0.0f, 1.6f);

        auto each = make_fast_each(count);
        while (yas_each_next(each)) {
            auto const &idx = yas_each_index(each);
            mesh_node.data().set_rect_position(region, idx, ui::matrix::rotation(angle_dif * idx) * trans_matrix);
        }

        mesh_node.node().color().set_value({.red = 0.0f, .green = 0.6f, .blue = 1.0f});
        mesh_node.node().alpha().set_value(0.0f);
        this->node.add_sub_node(mesh_node.node());
    }

    static ui::action _make_rotate_action(ui::node &target) {
        auto rotate_action = ui::make_action(
            {.target = target, .end_angle = -360.0f, .continuous_action = {.duration = 2.0f, .loop_count = 0}});

        auto scale_action = ui::make_action({.target = target,
                                             .begin_scale = {.v = 10.0f},
                                             .end_scale = {.v = 15.0f},
                                             .continuous_action = {.duration = 5.0f, .loop_count = 0}});
        scale_action.set_value_transformer(
            ui::connect({ui::ping_pong_transformer(), ui::ease_in_out_sine_transformer()}));

        return ui::parallel_action{{.actions = {std::move(rotate_action), std::move(scale_action)}}};
    }

    static base _make_event_observer(ui::node &node, ui::renderer &renderer) {
        return renderer.event_manager()
            .chain(ui::event_manager::method::cursor_changed)
            .perform([weak_node = to_weak(node), weak_action = weak<ui::action>{}](ui::event const &event) mutable {
                if (auto node = weak_node.lock()) {
                    auto const &value = event.get<ui::cursor>();

                    node.position().set_value(node.parent().convert_position(value.position()));

                    if (auto renderer = node.renderer()) {
                        for (auto child_node : node.children()) {
                            auto make_fade_action = [](ui::node &node, float const alpha) {
                                return ui::make_action({.target = node,
                                                        .begin_alpha = node.alpha().raw(),
                                                        .end_alpha = alpha,
                                                        .continuous_action = {.duration = 0.5}});
                            };

                            switch (event.phase()) {
                                case ui::event_phase::began: {
                                    if (auto prev_action = weak_action.lock()) {
                                        renderer.erase_action(prev_action);
                                    }

                                    auto action = make_fade_action(child_node, 1.0f);
                                    renderer.insert_action(action);
                                    weak_action = action;
                                } break;

                                case ui::event_phase::ended: {
                                    if (auto prev_action = weak_action.lock()) {
                                        renderer.erase_action(prev_action);
                                    }

                                    auto action = make_fade_action(child_node, 0.0f);
                                    renderer.insert_action(action);
                                    weak_action = action;
                                } break;

                                default:
                                    break;
                            }
                        }
                    }
                }
            })
            .end();
    }

    chaining::any_observer_ptr _renderer_observer = nullptr;
};

sample::cursor::cursor() : base(std::make_shared<impl>()) {
    impl_ptr<impl>()->prepare(*this);
}

sample::cursor::cursor(std::nullptr_t) : base(nullptr) {
}

ui::node &sample::cursor::node() {
    return impl_ptr<impl>()->node;
}
