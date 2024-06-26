//
//  yas_sample_touch_holder.cpp
//

#include "yas_sample_touch_holder.h"

using namespace yas;
using namespace yas::ui;

namespace yas::sample {
struct touch_object {
    std::shared_ptr<node> node = nullptr;
    std::weak_ptr<action> scale_action;
};
}  // namespace yas::sample

sample::touch_holder::touch_holder(std::shared_ptr<ui::event_manager> const &event_manager,
                                   std::shared_ptr<ui::action_manager> const &action_manager) {
    this->_rect_plane_data->set_rect_position({.origin = {-0.5f, -0.5f}, .size = {1.0f, 1.0f}}, 0);

    event_manager
        ->observe([this, weak_action_manager = to_weak(action_manager)](auto const &event) {
            if (event->type() == event_type::touch) {
                this->_update_touch_node(event, weak_action_manager.lock());
            }
        })
        .end()
        ->set_to(this->_event_canceller);
}

void sample::touch_holder::set_texture(std::shared_ptr<texture> const &texture) {
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

std::shared_ptr<node> const &sample::touch_holder::node() {
    return this->root_node;
}

void sample::touch_holder::_update_touch_node(std::shared_ptr<event> const &event,
                                              std::shared_ptr<ui::action_manager> const &action_manager) {
    auto const identifier = event->identifier();
    auto const &value = event->get<touch>();

    switch (event->phase()) {
        case event_phase::began: {
            this->_insert_touch_node(identifier, action_manager);
            this->_move_touch_node(identifier, value.position);
        } break;

        case event_phase::changed: {
            this->_move_touch_node(identifier, value.position);
        } break;

        case event_phase::ended:
        case event_phase::canceled: {
            this->_move_touch_node(identifier, value.position);
            this->_erase_touch_node(identifier, action_manager);
        } break;

        default:
            break;
    }
}

void sample::touch_holder::_set_texture(std::shared_ptr<texture> const &texture) {
    this->_texture = texture;

    for (auto &touch_object : this->_objects) {
        if (auto &node = touch_object.second.node) {
            node->meshes().at(0)->set_texture(this->_texture);
        }
    }
}

void sample::touch_holder::_insert_touch_node(uintptr_t const identifier,
                                              std::shared_ptr<ui::action_manager> const &action_manager) {
    if (this->_objects.count(identifier) > 0) {
        return;
    }

    auto const node = node::make_shared();
    auto const mesh = mesh::make_shared({}, this->_rect_plane_data->dynamic_vertex_data(),
                                        this->_rect_plane_data->dynamic_index_data(), this->_texture);
    node->set_meshes({mesh});
    node->set_scale({.v = 0.0f});
    node->set_alpha(0.0f);

    root_node->add_sub_node(node);

    auto scale_action1 = make_action({.target = node,
                                      .begin_scale = {.v = 0.1f},
                                      .end_scale = {.v = 200.0f},
                                      .duration = 0.1,
                                      .value_transformer = ease_in_sine_transformer()});

    auto scale_action2 = make_action({.target = node,
                                      .begin_scale = {.v = 200.0f},
                                      .end_scale = {.v = 100.0f},
                                      .duration = 0.2,
                                      .value_transformer = ease_out_sine_transformer()});

    auto scale_action = action::make_sequence(
        {.elements = {{.action = scale_action1, .duration = 0.1}, {.action = scale_action2, .duration = 0.2}}});

    auto alpha_action = make_action({.target = node, .begin_alpha = 0.0f, .end_alpha = 1.0f, .duration = 0.3});

    auto action =
        parallel_action::make_shared({.actions = {std::move(scale_action), std::move(alpha_action)}})->raw_action();

    if (action_manager) {
        action_manager->insert_action(action);
    }

    this->_objects.emplace(std::make_pair(identifier, touch_object{.node = std::move(node), .scale_action = action}));
}

void sample::touch_holder::_move_touch_node(uintptr_t const identifier, point const &position) {
    if (this->_objects.count(identifier)) {
        auto &touch_object = this->_objects.at(identifier);
        auto &node = touch_object.node;
        node->set_position(node->parent()->convert_position(position));
    }
}

void sample::touch_holder::_erase_touch_node(uintptr_t const identifier,
                                             std::shared_ptr<ui::action_manager> const &action_manager) {
    if (this->_objects.count(identifier)) {
        auto &touch_object = this->_objects.at(identifier);

        if (auto prev_action = touch_object.scale_action.lock()) {
            if (action_manager) {
                action_manager->erase_action(prev_action);
            }

            touch_object.scale_action.reset();
        }

        auto const &node = touch_object.node;

        auto scale_action = make_action({.target = node,
                                         .begin_scale = touch_object.node->scale(),
                                         .end_scale = {.v = 300.0f},
                                         .duration = 0.3,
                                         .value_transformer = ease_out_sine_transformer(),
                                         .completion = [node] { node->remove_from_super_node(); }});

        auto alpha_action =
            make_action({.target = node,
                         .begin_alpha = node->alpha(),
                         .end_alpha = 0.0f,
                         .duration = 0.3,
                         .value_transformer = ui::connect({ease_out_sine_transformer(), ease_out_sine_transformer()})});

        auto action =
            parallel_action::make_shared({.actions = {std::move(scale_action), std::move(alpha_action)}})->raw_action();

        if (action_manager) {
            action_manager->insert_action(action);
        }

        this->_objects.erase(identifier);
    }
}

sample::touch_holder_ptr sample::touch_holder::make_shared(std::shared_ptr<ui::event_manager> const &event_manager,
                                                           std::shared_ptr<ui::action_manager> const &action_manager) {
    return std::shared_ptr<touch_holder>(new touch_holder{event_manager, action_manager});
}
