//
//  yas_sample_touch_holder.cpp
//

#include "yas_sample_touch_holder.h"

using namespace yas;

namespace yas::sample {
struct touch_object {
    ui::node_ptr node = nullptr;
    std::weak_ptr<ui::action> scale_action;
};
}

sample::touch_holder::touch_holder() {
    this->_rect_plane_data->set_rect_position({.origin = {-0.5f, -0.5f}, .size = {1.0f, 1.0f}}, 0);

    this->_renderer_canceller = root_node->observe_renderer(
        [this, event_canceller = observing::cancellable_ptr{nullptr}](ui::renderer_ptr const &renderer) mutable {
            if (renderer) {
                renderer->event_manager()
                    ->observe([this](auto const &context) {
                        if (context.method == ui::event_manager::method::touch_changed) {
                            ui::event_ptr const &event = context.event;
                            this->_update_touch_node(event);
                        }
                    })
                    ->set_to(event_canceller);
            } else {
                event_canceller = nullptr;
            }
        },
        false);
}

void sample::touch_holder::set_texture(ui::texture_ptr const &texture) {
    this->_rect_plane_data->clear_observers();

    this->_set_texture(texture);

    if (!this->_texture) {
        return;
    }

    auto element = this->_texture->add_draw_handler({100, 100}, [](CGContextRef const ctx) {
        CGContextSetStrokeColorWithColor(ctx, [yas_objc_color whiteColor].CGColor);
        CGContextSetLineWidth(ctx, 1.0f);
        CGContextStrokeEllipseInRect(ctx, CGRectMake(2, 2, 96, 96));
    });

    this->_rect_plane_data->observe_rect_tex_coords(element, 0);
}

ui::node_ptr const &sample::touch_holder::node() {
    return this->root_node;
}

void sample::touch_holder::_update_touch_node(ui::event_ptr const &event) {
    auto const identifier = event->identifier();
    auto const &value = event->get<ui::touch>();

    switch (event->phase()) {
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

void sample::touch_holder::_set_texture(ui::texture_ptr const &texture) {
    this->_texture = texture;

    for (auto &touch_object : this->_objects) {
        if (auto &node = touch_object.second.node) {
            node->mesh()->value()->set_texture(this->_texture);
        }
    }
}

void sample::touch_holder::_insert_touch_node(uintptr_t const identifier) {
    if (this->_objects.count(identifier) > 0) {
        return;
    }

    auto node = ui::node::make_shared();
    auto mesh = ui::mesh::make_shared();
    mesh->set_mesh_data(this->_rect_plane_data->dynamic_mesh_data());
    mesh->set_texture(this->_texture);
    node->mesh()->set_value(mesh);
    node->scale()->set_value({.v = 0.0f});
    node->alpha()->set_value(0.0f);

    root_node->add_sub_node(node);

    auto scale_action1 = ui::make_action({.target = node,
                                          .begin_scale = {.v = 0.1f},
                                          .end_scale = {.v = 200.0f},
                                          .continuous_action = {.duration = 0.1}});
    scale_action1->set_value_transformer(ui::ease_in_sine_transformer());

    auto scale_action2 = ui::make_action({.target = node,
                                          .begin_scale = {.v = 200.0f},
                                          .end_scale = {.v = 100.0f},
                                          .continuous_action = {.duration = 0.2}});
    scale_action2->set_value_transformer(ui::ease_out_sine_transformer());

    auto scale_action = ui::make_action_sequence({scale_action1, scale_action2}, std::chrono::system_clock::now());

    auto alpha_action = ui::make_action(
        {.target = node, .begin_alpha = 0.0f, .end_alpha = 1.0f, .continuous_action = {.duration = 0.3}});

    auto action = ui::parallel_action::make_shared(
        {.target = node, .actions = {std::move(scale_action), std::move(alpha_action)}});

    root_node->renderer()->insert_action(action);

    this->_objects.emplace(std::make_pair(identifier, touch_object{.node = std::move(node), .scale_action = action}));
}

void sample::touch_holder::_move_touch_node(uintptr_t const identifier, ui::point const &position) {
    if (this->_objects.count(identifier)) {
        auto &touch_object = this->_objects.at(identifier);
        auto &node = touch_object.node;
        node->position()->set_value(node->parent()->convert_position(position));
    }
}

void sample::touch_holder::_erase_touch_node(uintptr_t const identifier) {
    auto renderer = root_node->renderer();
    if (this->_objects.count(identifier)) {
        auto &touch_object = this->_objects.at(identifier);

        if (auto prev_action = touch_object.scale_action.lock()) {
            renderer->erase_action(prev_action);
            touch_object.scale_action.reset();
        }

        auto const &node = touch_object.node;

        auto scale_action = ui::make_action({.target = node,
                                             .begin_scale = touch_object.node->scale()->value(),
                                             .end_scale = {.v = 300.0f},
                                             .continuous_action = {.duration = 0.3}});
        scale_action->set_value_transformer(ui::ease_out_sine_transformer());
        scale_action->set_completion_handler([node = node]() mutable { node->remove_from_super_node(); });

        auto alpha_action = ui::make_action({.target = node,
                                             .begin_alpha = node->alpha()->value(),
                                             .end_alpha = 0.0f,
                                             .continuous_action = {.duration = 0.3}});
        alpha_action->set_value_transformer(
            ui::connect({ui::ease_out_sine_transformer(), ui::ease_out_sine_transformer()}));

        auto action = ui::parallel_action::make_shared(
            {.target = node, .actions = {std::move(scale_action), std::move(alpha_action)}});

        renderer->insert_action(action);

        this->_objects.erase(identifier);
    }
}

sample::touch_holder_ptr sample::touch_holder::make_shared() {
    return std::shared_ptr<touch_holder>(new touch_holder{});
}
