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

    impl(id<MTLDevice> const device, double const scale_factor) {
        assert(device);

        auto texture_result = ui::make_texture(device, {128, 128}, scale_factor);
        assert(texture_result);

        _texture = texture_result.value();

        ui::image image{{100, 100}, scale_factor};
        image.draw([](CGContextRef const ctx) {
            CGContextSetStrokeColorWithColor(ctx, [yas_objc_color whiteColor].CGColor);
            CGContextSetLineWidth(ctx, 1.0f);
            CGContextStrokeEllipseInRect(ctx, CGRectMake(2, 2, 96, 96));
        });

        auto image_result = _texture.add_image(image);
        assert(image_result);

        auto sq_mesh_data = ui::make_square_mesh_data(1);
        sq_mesh_data.set_square_position({-0.5f, -0.5f, 1.0f, 1.0f}, 0);
        sq_mesh_data.set_square_tex_coords(image_result.value(), 0);
        _mesh_data = std::move(sq_mesh_data.dynamic_mesh_data());
    }

    void setup_renderer_observer() {
        root_node.dispatch_method(ui::node_method::renderer_changed);
        _renderer_observer = root_node.subject().make_observer(
            ui::node_method::renderer_changed,
            [weak_touch_holder = to_weak(cast<touch_holder>()),
             event_observer = base{nullptr}](auto const &context) mutable {
                if (auto touch_holder = weak_touch_holder.lock()) {
                    auto impl = touch_holder.impl_ptr<touch_holder::impl>();
                    auto &node = context.value;
                    if (auto renderer = node.renderer()) {
                        event_observer = _make_event_observer(touch_holder, renderer);
                    } else {
                        event_observer = nullptr;
                    }
                }
            });
    }

   private:
    static base _make_event_observer(sample::touch_holder &touch_holder, ui::renderer &renderer) {
        return renderer.event_manager().subject().make_observer(
            ui::event_method::touch_changed, [weak_touch_holder = to_weak(touch_holder)](auto const &context) mutable {
                if (auto touch_holder = weak_touch_holder.lock()) {
                    auto impl = touch_holder.impl_ptr<touch_holder::impl>();
                    ui::event const &event = context.value;
                    auto const identifier = event.identifier();
                    auto const &value = event.get<ui::touch>();

                    switch (event.phase()) {
                        case ui::event_phase::began: {
                            impl->_insert_touch_node(identifier);
                            impl->_move_touch_node(identifier, value.position());
                        } break;

                        case ui::event_phase::changed: {
                            impl->_move_touch_node(identifier, value.position());
                        } break;

                        case ui::event_phase::ended:
                        case ui::event_phase::canceled: {
                            impl->_move_touch_node(identifier, value.position());
                            impl->_erase_touch_node(identifier);
                        } break;

                        default:
                            break;
                    }
                }
            });
    }

    void _insert_touch_node(uintptr_t const identifier) {
        if (_objects.count(identifier) > 0) {
            return;
        }

        ui::node node;
        ui::mesh mesh;
        mesh.set_mesh_data(_mesh_data);
        mesh.set_texture(_texture);
        node.set_mesh(mesh);
        node.set_scale(0.0f);

        root_node.add_sub_node(node);

        auto scale_action1 =
            ui::make_action({.start_scale = 0.1f, .end_scale = 200.0f, .continuous_action = {.duration = 0.1}});
        scale_action1.set_value_transformer(ui::ease_in_transformer());
        scale_action1.set_target(node);

        auto scale_action2 =
            ui::make_action({.start_scale = 200.0f, .end_scale = 100.0f, .continuous_action = {.duration = 0.2}});
        scale_action2.set_value_transformer(ui::ease_out_transformer());
        scale_action2.set_target(node);

        auto action = ui::make_action_sequence({scale_action1, scale_action2}, std::chrono::system_clock::now());
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

            auto action = ui::make_action(
                {.start_scale = touch_object.node.scale(), .end_scale = 0.0f, .continuous_action = {.duration = 0.3}});
            action.set_value_transformer(ui::ease_out_transformer());
            action.set_target(touch_object.node);
            action.set_completion_handler([node = touch_object.node]() mutable { node.remove_from_super_node(); });

            renderer.insert_action(action);

            _objects.erase(identifier);
        }
    }

    std::unordered_map<uintptr_t, touch_object> _objects;
    ui::texture _texture = nullptr;
    ui::mesh_data _mesh_data = nullptr;
    base _renderer_observer = nullptr;
};

sample::touch_holder::touch_holder(id<MTLDevice> const device, double const scale_factor)
    : base(std::make_shared<impl>(device, scale_factor)) {
    impl_ptr<impl>()->setup_renderer_observer();
}

sample::touch_holder::touch_holder(std::nullptr_t) : base(nullptr) {
}

ui::node &sample::touch_holder::node() {
    return impl_ptr<impl>()->root_node;
}
