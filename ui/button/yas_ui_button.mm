//
//  yas_ui_button.mm
//

#include "yas_ui_button.h"
#include <cpp_utils/yas_fast_each.h>
#include <ui/yas_ui_angle.h>
#include <ui/yas_ui_collider.h>
#include <ui/yas_ui_detector.h>
#include <ui/yas_ui_event.h>
#include <ui/yas_ui_layout_guide.h>
#include <ui/yas_ui_mesh.h>
#include <ui/yas_ui_node.h>
#include <ui/yas_ui_rect_plane.h>
#include <ui/yas_ui_texture.h>

using namespace yas;
using namespace yas::ui;

button::button(region const &region, std::size_t const state_count,
               std::shared_ptr<ui::event_observable> const &event_manager,
               std::shared_ptr<ui::collider_detectable> const &detector)
    : _rect_plane(rect_plane::make_shared(state_count * 2, 1)),
      _layout_guide(layout_region_guide::make_shared(region)),
      _state_count(state_count),
      _weak_detector(detector) {
    this->_rect_plane->node()->set_collider(collider::make_shared());

    this->_update_rect_positions(this->_layout_guide->region(), state_count);
    this->_update_rect_index();

    event_manager
        ->observe([this](auto const &event) {
            if (event->type() == event_type::touch) {
                this->_update_tracking(event);
            }
        })
        .end()
        ->add_to(this->_pool);

    this->_make_leave_observings()->add_to(this->_pool);
    this->_make_collider_observings()->add_to(this->_pool);

    this->_layout_guide
        ->observe([this, state_count = this->_state_count](ui::region const &value) {
            this->_update_rect_positions(value, state_count);
        })
        .end()
        ->add_to(this->_pool);
}

void button::set_texture(std::shared_ptr<ui::texture> const &texture) {
    this->rect_plane()->node()->mesh()->set_texture(texture);
}

std::shared_ptr<texture> const &button::texture() const {
    return this->_rect_plane->node()->mesh()->texture();
}

std::size_t button::state_count() const {
    return this->_state_count;
}

void button::set_state_index(std::size_t const idx) {
    if (idx >= this->_state_count) {
        throw std::invalid_argument("idx greater than or equal state count.");
    }

    this->_state_idx = idx;

    this->_update_rect_index();
}

std::size_t button::state_index() const {
    return this->_state_idx;
}

void button::set_can_begin_tracking(std::function<bool(std::shared_ptr<event> const &)> &&handler) {
    this->_can_begin_tracking = std::move(handler);
}

void button::set_can_indicate_tracking(std::function<bool(std::shared_ptr<event> const &)> &&handler) {
    this->_can_indicate_tracking = std::move(handler);
}

void button::cancel_tracking() {
    if (this->_tracking_event) {
        this->_cancel_tracking(this->_tracking_event);
    }
}

observing::endable button::observe(std::function<void(context const &)> &&handler) {
    return this->_notifier->observe(std::move(handler));
}

std::shared_ptr<rect_plane> const &button::rect_plane() {
    return this->_rect_plane;
}

std::shared_ptr<layout_region_guide> const &button::layout_guide() {
    return this->_layout_guide;
}

bool button::_is_tracking() {
    return !!this->_tracking_event;
}

bool button::_is_tracking(std::shared_ptr<event> const &event) {
    if (event && this->_tracking_event) {
        return *event == *this->_tracking_event;
    } else {
        return false;
    }
}

void button::_set_tracking_event(std::shared_ptr<event> const &event) {
    this->_tracking_event = event;

    this->_update_rect_index();
}

void button::_update_rect_positions(region const &region, std::size_t const state_count) {
    auto each = make_fast_each(state_count * 2);
    while (yas_each_next(each)) {
        this->_rect_plane->data()->set_rect_position(region, yas_each_index(each));
    }

    std::shared_ptr<collider> const &collider = this->_rect_plane->node()->collider();
    if (!collider->shape() || (collider->shape()->type_info() == typeid(shape::rect))) {
        collider->set_shape(shape::make_shared({.rect = region}));
    }
}

void button::_update_rect_index() {
    bool const can_indicate =
        !this->_can_indicate_tracking || (this->_tracking_event && this->_can_indicate_tracking(this->_tracking_event));
    std::size_t const idx = to_rect_index(this->_state_idx, this->_is_tracking() && can_indicate);
    this->_rect_plane->data()->set_rect_index(0, idx);
}

observing::cancellable_ptr button::_make_leave_observings() {
    std::shared_ptr<node> const &node = this->_rect_plane->node();

    auto pool = observing::canceller_pool::make_shared();

    node->observe_position([this](auto const &) {
            if (auto tracking_event = this->_tracking_event) {
                this->_leave_or_enter_or_move_tracking(tracking_event);
            }
        })
        .end()
        ->add_to(*pool);
    node->observe_angle([this](auto const &) {
            if (auto tracking_event = this->_tracking_event) {
                this->_leave_or_enter_or_move_tracking(tracking_event);
            }
        })
        .end()
        ->add_to(*pool);
    node->observe_scale([this](auto const &) {
            if (auto tracking_event = this->_tracking_event) {
                this->_leave_or_enter_or_move_tracking(tracking_event);
            }
        })
        .end()
        ->add_to(*pool);

    node->observe_collider([this](std::shared_ptr<collider> const &value) {
            if (!value) {
                if (auto tracking_event = this->_tracking_event) {
                    this->_cancel_tracking(tracking_event);
                }
            }
        })
        .end()
        ->add_to(*pool);
    node->observe_is_enabled([this](bool const &value) {
            if (!value) {
                if (auto tracking_event = this->_tracking_event) {
                    this->_cancel_tracking(tracking_event);
                }
            }
        })
        .sync()
        ->add_to(*pool);

    return pool;
}

observing::cancellable_ptr button::_make_collider_observings() {
    auto &node = this->_rect_plane->node();

    auto pool = observing::canceller_pool::make_shared();

    node->collider()
        ->observe_shape([this](std::shared_ptr<shape> const &shape) {
            if (!shape) {
                if (auto tracking_event = this->_tracking_event) {
                    this->_cancel_tracking(tracking_event);
                }
            }
        })
        .end()
        ->add_to(*pool);

    node->collider()
        ->observe_enabled([this](bool const &enabled) {
            if (!enabled) {
                if (auto tracking_event = this->_tracking_event) {
                    this->_cancel_tracking(tracking_event);
                }
            }
        })
        .end()
        ->add_to(*pool);

    return pool;
}

void button::_update_tracking(std::shared_ptr<event> const &event) {
    auto &node = this->_rect_plane->node();
    if (auto const detector = this->_weak_detector.lock()) {
        auto const &touch_event = event->get<touch>();
        switch (event->phase()) {
            case event_phase::began:
                if (!this->_is_tracking()) {
                    if (this->_can_begin_tracking_value(event) &&
                        detector->detect(touch_event.position, node->collider())) {
                        this->_set_tracking_event(event);
                        this->_send_notify(method::began, event);
                    }
                }
                break;
            case event_phase::stationary:
            case event_phase::changed: {
                this->_leave_or_enter_or_move_tracking(event);
            } break;
            case event_phase::ended:
                if (this->_is_tracking(event)) {
                    auto const send_event = event;
                    this->_set_tracking_event(nullptr);
                    this->_send_notify(method::ended, send_event);
                }
                break;
            case event_phase::canceled:
                this->_cancel_tracking(event);
                break;
            default:
                break;
        }
    }
}

void button::_leave_or_enter_or_move_tracking(std::shared_ptr<event> const &event) {
    auto &node = this->_rect_plane->node();
    if (auto const detector = this->_weak_detector.lock()) {
        auto const &touch_event = event->get<touch>();
        bool const is_event_tracking = this->_is_tracking(event);
        bool const is_detected = detector->detect(touch_event.position, node->collider());
        if (!is_event_tracking && is_detected && this->_can_begin_tracking_value(event)) {
            this->_set_tracking_event(event);
            this->_send_notify(method::entered, event);
        } else if (is_event_tracking && !is_detected) {
            this->_set_tracking_event(nullptr);
            this->_send_notify(method::leaved, event);
        } else if (is_event_tracking) {
            this->_send_notify(method::moved, event);
        }
    }
}

void button::_cancel_tracking(std::shared_ptr<event> const &event) {
    if (this->_is_tracking(event)) {
        auto const send_event = event;
        this->_set_tracking_event(nullptr);
        this->_send_notify(method::canceled, send_event);
    }
}

void button::_send_notify(method const method, std::shared_ptr<event> const &event) {
    context const context{.method = method, .touch = event->get<touch>()};
    this->_notifier->notify(context);
}

std::shared_ptr<button> button::make_shared(region const &region,
                                            std::shared_ptr<ui::event_observable> const &event_manager,
                                            std::shared_ptr<ui::collider_detectable> const &detector) {
    return make_shared(region, 1, event_manager, detector);
}

std::shared_ptr<button> button::make_shared(region const &region, std::size_t const state_count,
                                            std::shared_ptr<ui::event_observable> const &event_manager,
                                            std::shared_ptr<ui::collider_detectable> const &detector) {
    return std::shared_ptr<button>(new button{region, state_count, event_manager, detector});
}

bool button::_can_begin_tracking_value(std::shared_ptr<event> const &event) const {
    return !this->_can_begin_tracking || (this->_can_begin_tracking && this->_can_begin_tracking(event));
}

bool button::_can_indicate_tracking_value(std::shared_ptr<event> const &event) const {
    return !this->_can_indicate_tracking || (this->_can_indicate_tracking && this->_can_indicate_tracking(event));
}

#pragma mark -

std::size_t yas::to_rect_index(std::size_t const state_idx, bool is_tracking) {
    return state_idx * 2 + (is_tracking ? 1 : 0);
}

std::string yas::to_string(button::method const &method) {
    switch (method) {
        case button::method::began:
            return "began";
        case button::method::entered:
            return "entered";
        case button::method::moved:
            return "moved";
        case button::method::leaved:
            return "leaved";
        case button::method::ended:
            return "ended";
        case button::method::canceled:
            return "canceled";
    }
}

std::ostream &operator<<(std::ostream &os, yas::ui::button::method const &method) {
    os << to_string(method);
    return os;
}
