//
//  yas_sample_touch_holder.cpp
//

#include "yas_sample_touch_holder.h"

using namespace yas;

namespace yas {
namespace sample {
    struct touch_object {
        ui::node node = nullptr;
        weak<ui::action> scale_action;
    };
}
}

struct sample::touch_holder::impl : base::impl {
    ui::node root_node;

    impl() {
        _square_mesh_data.set_square_position({-0.5f, -0.5f, 1.0f, 1.0f}, 0);
    }

    void setup_renderer_observer() {
        root_node.dispatch_method(ui::node_method::renderer_changed);
        _renderer_observer = root_node.subject().make_observer(ui::node_method::renderer_changed, [
            weak_touch_holder = to_weak(cast<touch_holder>()),
            event_observer = base{nullptr},
            scale_observer = base{nullptr}
        ](auto const &context) mutable {
            auto &node = context.value;
            if (auto renderer = node.renderer()) {
                event_observer = renderer.event_manager().subject().make_observer(
                    ui::event_method::touch_changed, [weak_touch_holder](auto const &context) mutable {
                        if (auto touch_holder = weak_touch_holder.lock()) {
                            ui::event const &event = context.value;
                            touch_holder.impl_ptr<impl>()->update_touch_node(event);
                        }
                    });

                scale_observer = renderer.subject().make_observer(
                    ui::renderer_method::scale_factor_changed, [weak_touch_holder](auto const &context) {
                        if (auto touch_holder = weak_touch_holder.lock()) {
                            touch_holder.impl_ptr<impl>()->update_texture();
                        }
                    });
            } else {
                event_observer = nullptr;
                scale_observer = nullptr;
            }

            if (auto touch_holder = weak_touch_holder.lock()) {
                touch_holder.impl_ptr<impl>()->update_texture();
            }
        });
    }

    void update_texture() {
        _set_texture(nullptr);

        auto renderer = root_node.renderer();
        if (!renderer) {
            return;
        }

        double const scale_factor = renderer.scale_factor();
        if (scale_factor == 0.0) {
            return;
        }

        auto const device = renderer.device();

        assert(device);

        auto texture_result = ui::make_texture(device, {128, 128}, scale_factor);
        assert(texture_result);

        _set_texture(std::move(texture_result.value()));

        ui::image image{{100, 100}, scale_factor};
        image.draw([](CGContextRef const ctx) {
            CGContextSetStrokeColorWithColor(ctx, [yas_objc_color whiteColor].CGColor);
            CGContextSetLineWidth(ctx, 1.0f);
            CGContextStrokeEllipseInRect(ctx, CGRectMake(2, 2, 96, 96));
        });

        auto image_result = _texture.add_image(image);
        assert(image_result);

        _square_mesh_data.set_square_tex_coords(image_result.value(), 0);
    }

    void update_touch_node(ui::event const &event) {
        auto const identifier = event.identifier();
        auto const &value = event.get<ui::touch>();

        switch (event.phase()) {
            case ui::event_phase::began: {
                _insert_touch_node(identifier);
                _move_touch_node(identifier, value.position());
            } break;

            case ui::event_phase::changed: {
                _move_touch_node(identifier, value.position());
            } break;

            case ui::event_phase::ended:
            case ui::event_phase::canceled: {
                _move_touch_node(identifier, value.position());
                _erase_touch_node(identifier);
            } break;

            default:
                break;
        }
    }

   private:
    void _set_texture(ui::texture texture) {
        _texture = std::move(texture);

        for (auto &touch_object : _objects) {
            if (auto &node = touch_object.second.node) {
                node.mesh().set_texture(_texture);
            }
        }
    }
    void _insert_touch_node(uintptr_t const identifier) {
        if (_objects.count(identifier) > 0) {
            return;
        }

        ui::node node;
        ui::mesh mesh;
        mesh.set_mesh_data(_square_mesh_data.dynamic_mesh_data());
        mesh.set_texture(_texture);
        node.set_mesh(mesh);
        node.set_scale(0.0f);
        node.set_alpha(0.0f);

        root_node.push_back_sub_node(node);

        auto scale_action1 =
            ui::make_action({.start_scale = 0.1f, .end_scale = 200.0f, .continuous_action = {.duration = 0.1}});
        scale_action1.set_value_transformer(ui::ease_in_transformer());
        scale_action1.set_target(node);

        auto scale_action2 =
            ui::make_action({.start_scale = 200.0f, .end_scale = 100.0f, .continuous_action = {.duration = 0.2}});
        scale_action2.set_value_transformer(ui::ease_out_transformer());
        scale_action2.set_target(node);

        auto scale_action = ui::make_action_sequence({scale_action1, scale_action2}, std::chrono::system_clock::now());
        scale_action.set_target(node);

        auto alpha_action =
            ui::make_action({.start_alpha = 0.0f, .end_alpha = 1.0f, .continuous_action = {.duration = 0.3}});
        alpha_action.set_target(node);

        ui::parallel_action action;
        action.insert_action(scale_action);
        action.insert_action(alpha_action);
        action.set_target(node);

        root_node.renderer().insert_action(action);

        _objects.emplace(std::make_pair(identifier, touch_object{.node = std::move(node), .scale_action = action}));
    }

    void _move_touch_node(uintptr_t const identifier, ui::point const &position) {
        if (_objects.count(identifier)) {
            auto &touch_object = _objects.at(identifier);
            auto &node = touch_object.node;
            node.set_position(node.parent().convert_position(position));
        }
    }

    void _erase_touch_node(uintptr_t const identifier) {
        auto renderer = root_node.renderer();
        if (_objects.count(identifier)) {
            auto &touch_object = _objects.at(identifier);

            if (auto prev_action = touch_object.scale_action.lock()) {
                renderer.erase_action(prev_action);
                touch_object.scale_action = nullptr;
            }

            auto const &node = touch_object.node;

            auto scale_action = ui::make_action({.start_scale = touch_object.node.scale(),
                                                 .end_scale = 300.0f,
                                                 .continuous_action = {.duration = 0.3}});
            scale_action.set_value_transformer(ui::ease_out_transformer());
            scale_action.set_target(node);
            scale_action.set_completion_handler([node = node]() mutable { node.remove_from_super_node(); });

            auto alpha_action = ui::make_action(
                {.start_alpha = node.alpha(), .end_alpha = 0.0f, .continuous_action = {.duration = 0.3}});
            alpha_action.set_value_transformer(ui::connect({ui::ease_out_transformer(), ui::ease_out_transformer()}));
            alpha_action.set_target(node);

            ui::parallel_action action;
            action.insert_action(scale_action);
            action.insert_action(alpha_action);
            action.set_target(node);

            renderer.insert_action(action);

            _objects.erase(identifier);
        }
    }

    std::unordered_map<uintptr_t, touch_object> _objects;
    ui::texture _texture = nullptr;
    ui::square_mesh_data _square_mesh_data = ui::make_square_mesh_data(1);
    base _renderer_observer = nullptr;
};

sample::touch_holder::touch_holder() : base(std::make_shared<impl>()) {
    impl_ptr<impl>()->setup_renderer_observer();
}

sample::touch_holder::touch_holder(std::nullptr_t) : base(nullptr) {
}

ui::node &sample::touch_holder::node() {
    return impl_ptr<impl>()->root_node;
}
