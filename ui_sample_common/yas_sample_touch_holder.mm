//
//  yas_sample_touch_holder.cpp
//

#include "yas_sample_touch_holder.h"

using namespace yas;

namespace yas::sample {
struct touch_object {
    ui::node node = nullptr;
    weak<ui::action> scale_action;
};
}

struct sample::touch_holder::impl : base::impl {
    ui::node root_node;

    impl() {
        this->_rect_plane_data.set_rect_position({.origin = {-0.5f, -0.5f}, .size = {1.0f, 1.0f}}, 0);
    }

    void prepare(sample::touch_holder &holder) {
        this->_renderer_observer =
            root_node.chain_renderer()
                .perform([weak_touch_holder = to_weak(holder),
                          event_observer = chaining::any_observer{nullptr}](ui::renderer const &value) mutable {
                    if (auto renderer = value) {
                        event_observer = renderer.event_manager()
                                             .chain(ui::event_manager::method::touch_changed)
                                             .perform([weak_touch_holder](ui::event const &event) {
                                                 if (auto touch_holder = weak_touch_holder.lock()) {
                                                     touch_holder.impl_ptr<impl>()->update_touch_node(event);
                                                 }
                                             })
                                             .end();
                    } else {
                        event_observer = nullptr;
                    }
                })
                .end();
    }

    void set_texture(ui::texture &&texture) {
        this->_rect_plane_data.clear_observers();

        this->_set_texture(std::move(texture));

        if (!this->_texture) {
            return;
        }

        auto element = this->_texture.add_draw_handler({100, 100}, [](CGContextRef const ctx) {
            CGContextSetStrokeColorWithColor(ctx, [yas_objc_color whiteColor].CGColor);
            CGContextSetLineWidth(ctx, 1.0f);
            CGContextStrokeEllipseInRect(ctx, CGRectMake(2, 2, 96, 96));
        });

        this->_rect_plane_data.observe_rect_tex_coords(element, 0);
    }

    void update_touch_node(ui::event const &event) {
        auto const identifier = event.identifier();
        auto const &value = event.get<ui::touch>();

        switch (event.phase()) {
            case ui::event_phase::began: {
                this->_insert_touch_node(identifier);
                this->_move_touch_node(identifier, value.position());
            } break;

            case ui::event_phase::changed: {
                this->_move_touch_node(identifier, value.position());
            } break;

            case ui::event_phase::ended:
            case ui::event_phase::canceled: {
                this->_move_touch_node(identifier, value.position());
                this->_erase_touch_node(identifier);
            } break;

            default:
                break;
        }
    }

   private:
    void _set_texture(ui::texture texture) {
        this->_texture = std::move(texture);

        for (auto &touch_object : this->_objects) {
            if (auto &node = touch_object.second.node) {
                node.mesh().raw().set_texture(this->_texture);
            }
        }
    }
    void _insert_touch_node(uintptr_t const identifier) {
        if (this->_objects.count(identifier) > 0) {
            return;
        }

        ui::node node;
        ui::mesh mesh;
        mesh.set_mesh_data(this->_rect_plane_data.dynamic_mesh_data());
        mesh.set_texture(this->_texture);
        node.mesh().set_value(mesh);
        node.scale().set_value({.v = 0.0f});
        node.alpha().set_value(0.0f);

        root_node.add_sub_node(node);

        auto scale_action1 = ui::make_action({.target = node,
                                              .begin_scale = {.v = 0.1f},
                                              .end_scale = {.v = 200.0f},
                                              .continuous_action = {.duration = 0.1}});
        scale_action1.set_value_transformer(ui::ease_in_sine_transformer());

        auto scale_action2 = ui::make_action({.target = node,
                                              .begin_scale = {.v = 200.0f},
                                              .end_scale = {.v = 100.0f},
                                              .continuous_action = {.duration = 0.2}});
        scale_action2.set_value_transformer(ui::ease_out_sine_transformer());

        auto scale_action = ui::make_action_sequence({scale_action1, scale_action2}, std::chrono::system_clock::now());

        auto alpha_action = ui::make_action(
            {.target = node, .begin_alpha = 0.0f, .end_alpha = 1.0f, .continuous_action = {.duration = 0.3}});

        ui::parallel_action action{{.target = node, .actions = {std::move(scale_action), std::move(alpha_action)}}};

        root_node.renderer().insert_action(action);

        this->_objects.emplace(
            std::make_pair(identifier, touch_object{.node = std::move(node), .scale_action = action}));
    }

    void _move_touch_node(uintptr_t const identifier, ui::point const &position) {
        if (this->_objects.count(identifier)) {
            auto &touch_object = this->_objects.at(identifier);
            auto &node = touch_object.node;
            node.position().set_value(node.parent().convert_position(position));
        }
    }

    void _erase_touch_node(uintptr_t const identifier) {
        auto renderer = root_node.renderer();
        if (this->_objects.count(identifier)) {
            auto &touch_object = this->_objects.at(identifier);

            if (auto prev_action = touch_object.scale_action.lock()) {
                renderer.erase_action(prev_action);
                touch_object.scale_action = nullptr;
            }

            auto const &node = touch_object.node;

            auto scale_action = ui::make_action({.target = node,
                                                 .begin_scale = touch_object.node.scale().raw(),
                                                 .end_scale = {.v = 300.0f},
                                                 .continuous_action = {.duration = 0.3}});
            scale_action.set_value_transformer(ui::ease_out_sine_transformer());
            scale_action.set_completion_handler([node = node]() mutable { node.remove_from_super_node(); });

            auto alpha_action = ui::make_action({.target = node,
                                                 .begin_alpha = node.alpha().raw(),
                                                 .end_alpha = 0.0f,
                                                 .continuous_action = {.duration = 0.3}});
            alpha_action.set_value_transformer(
                ui::connect({ui::ease_out_sine_transformer(), ui::ease_out_sine_transformer()}));

            ui::parallel_action action{{.target = node, .actions = {std::move(scale_action), std::move(alpha_action)}}};

            renderer.insert_action(action);

            this->_objects.erase(identifier);
        }
    }

    std::unordered_map<uintptr_t, touch_object> _objects;
    ui::texture _texture = nullptr;
    ui::rect_plane_data _rect_plane_data{1};
    chaining::any_observer _renderer_observer = nullptr;
};

sample::touch_holder::touch_holder() : base(std::make_shared<impl>()) {
    impl_ptr<impl>()->prepare(*this);
}

sample::touch_holder::touch_holder(std::nullptr_t) : base(nullptr) {
}

void sample::touch_holder::set_texture(ui::texture texture) {
    impl_ptr<impl>()->set_texture(std::move(texture));
}

ui::node &sample::touch_holder::node() {
    return impl_ptr<impl>()->root_node;
}
