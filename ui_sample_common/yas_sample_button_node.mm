//
//  yas_ui_button_node.mm
//

#include "yas_each_index.h"
#include "yas_sample_button_node.h"
#include "yas_ui_collider.h"

using namespace yas;

#pragma mark - button_node::impl

struct sample::button_node::impl : base::impl {
    yas::subject<sample::button_node, sample::button_method> subject;
    ui::square_node square_node = ui::make_square_node(2, 1);

    impl() {
        _setup_node();
    }

    void setup_renderer_observer() {
        square_node.node().dispatch_method(ui::node_method::renderer_changed);

        _renderer_observer = square_node.node().subject().make_observer(ui::node_method::renderer_changed, [
            event_observer = base{nullptr},
            scale_observer = base{nullptr},
            weak_button_node = to_weak(cast<sample::button_node>())
        ](auto const &context) mutable {
            ui::node const &node = context.value;

            if (auto renderer = node.renderer()) {
                event_observer = renderer.event_manager().subject().make_observer(
                    ui::event_method::touch_changed, [weak_button_node](auto const &context) {
                        if (auto button_node = weak_button_node.lock()) {
                            button_node.impl_ptr<impl>()->update_tracking(context.value);
                        }
                    });

                scale_observer = renderer.subject().make_observer(
                    ui::renderer_method::scale_factor_changed, [weak_button_node](auto const &context) {
                        if (auto button_node = weak_button_node.lock()) {
                            button_node.impl_ptr<impl>()->update_texture();
                        }
                    });
            } else {
                event_observer = nullptr;
                scale_observer = nullptr;
            }

            if (auto button_node = weak_button_node.lock()) {
                button_node.impl_ptr<impl>()->update_texture();
            }
        });
    }

    bool is_tracking() {
        return !!_tracking_event;
    }

    bool is_tracking(ui::event const &event) {
        return event == _tracking_event;
    }

    void set_tracking_event(ui::event event) {
        _tracking_event = std::move(event);
        _update_square_index();
    }

    void update_texture() {
        auto &node = square_node.node();
        node.mesh().set_texture(nullptr);

        auto renderer = node.renderer();
        if (!renderer) {
            return;
        }

        double const scale_factor = renderer.scale_factor();
        if (scale_factor == 0.0) {
            return;
        }

        auto const device = renderer.device();

        float const radius = 60;
        uint32_t const width = radius * 2;

        auto texture = ui::make_texture(device, ui::uint_size{256, 128}, scale_factor).value();
        assert(texture);

        auto &square_mesh_data = square_node.square_mesh_data();

        ui::uint_size image_size{width, width};
        ui::image image{image_size, scale_factor};

        auto set_image_region = [&square_mesh_data](ui::uint_region const &pixel_region, bool const tracking) {
            std::size_t const sq_idx = tracking ? 1 : 0;
            square_mesh_data.set_square_tex_coords(pixel_region, sq_idx);
        };

        image.draw([&image_size](const CGContextRef ctx) {
            CGContextSetFillColorWithColor(ctx, [yas_objc_color colorWithRed:0.3 green:0.3 blue:0.3 alpha:1.0].CGColor);
            CGContextFillEllipseInRect(ctx, CGRectMake(0, 0, image_size.width, image_size.height));
        });

        if (auto texture_result = texture.add_image(image)) {
            set_image_region(texture_result.value(), false);
        }

        image.clear();
        image.draw([&image_size](const CGContextRef ctx) {
            CGContextSetFillColorWithColor(ctx, [yas_objc_color redColor].CGColor);
            CGContextFillEllipseInRect(ctx, CGRectMake(0, 0, image_size.width, image_size.height));
        });

        if (auto texture_result = texture.add_image(image)) {
            set_image_region(texture_result.value(), true);
        }

        square_node.node().mesh().set_texture(std::move(texture));
    }

    void update_tracking(ui::event const &event) {
        auto &node = square_node.node();
        if (auto renderer = node.renderer()) {
            auto const &detector = renderer.collision_detector();
            auto button_node = cast<sample::button_node>();

            auto const &touch_event = event.get<ui::touch>();
            switch (event.phase()) {
                case ui::event_phase::began:
                    if (!is_tracking()) {
                        if (detector.detect(touch_event.position(), node.collider())) {
                            set_tracking_event(event);
                            subject.notify(sample::button_method::began, button_node);
                        }
                    }
                    break;
                case ui::event_phase::stationary:
                case ui::event_phase::changed: {
                    bool const is_event_tracking = is_tracking(event);
                    bool is_detected = detector.detect(touch_event.position(), node.collider());
                    if (!is_event_tracking && is_detected) {
                        set_tracking_event(event);
                        subject.notify(sample::button_method::entered, button_node);
                    } else if (is_event_tracking && !is_detected) {
                        set_tracking_event(nullptr);
                        subject.notify(sample::button_method::leaved, button_node);
                    }
                } break;
                case ui::event_phase::ended:
                    if (is_tracking(event)) {
                        set_tracking_event(nullptr);
                        subject.notify(sample::button_method::ended, button_node);
                    }
                    break;
                case ui::event_phase::canceled:
                    if (is_tracking(event)) {
                        set_tracking_event(nullptr);
                        subject.notify(sample::button_method::canceled, button_node);
                    }
                    break;
                default:
                    break;
            }
        }
    }

   private:
    void _setup_node() {
        float const radius = 60;
        auto &square_mesh_data = square_node.square_mesh_data();

        ui::float_region region{-radius, -radius, radius * 2.0f, radius * 2.0f};
        for (auto const &idx : make_each(2)) {
            square_mesh_data.set_square_position(region, idx);
        }

        ui::collider collider;
        collider.set_shape(ui::collider_shape::circle);
        collider.set_radius(radius);
        square_node.node().set_collider(std::move(collider));

        _update_square_index();
    }

    void _update_square_index() {
        std::size_t const sq_idx = _tracking_event ? 1 : 0;
        square_node.square_mesh_data().set_square_index(0, sq_idx);
    }

    base _renderer_observer = nullptr;
    ui::event _tracking_event = nullptr;
};

#pragma mark - button_node

sample::button_node::button_node() : base(std::make_shared<impl>()) {
    impl_ptr<impl>()->setup_renderer_observer();
}

sample::button_node::button_node(std::nullptr_t) : base(nullptr) {
}

subject<sample::button_node, sample::button_method> &sample::button_node::subject() {
    return impl_ptr<impl>()->subject;
}

ui::square_node &sample::button_node::square_node() {
    return impl_ptr<impl>()->square_node;
}

std::string yas::to_string(sample::button_method const &method) {
    switch (method) {
        case sample::button_method::began:
            return "began";
        case sample::button_method::entered:
            return "entered";
        case sample::button_method::leaved:
            return "leaved";
        case sample::button_method::ended:
            return "ended";
        case sample::button_method::canceled:
            return "canceled";
    }
}
