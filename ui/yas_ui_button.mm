//
//  yas_ui_button.mm
//

#include "yas_ui_button.h"
#include <cpp_utils/yas_fast_each.h>
#include "yas_ui_angle.h"
#include "yas_ui_collider.h"
#include "yas_ui_detector.h"
#include "yas_ui_event.h"
#include "yas_ui_layout_guide.h"
#include "yas_ui_mesh.h"
#include "yas_ui_node.h"
#include "yas_ui_rect_plane.h"
#include "yas_ui_renderer.h"
#include "yas_ui_texture.h"

using namespace yas;

ui::button::button(ui::region const &region, std::size_t const state_count)
    : _rect_plane(ui::rect_plane::make_shared(state_count * 2, 1)),
      _layout_guide_rect(layout_guide_rect::make_shared(region)),
      _state_count(state_count) {
    this->_rect_plane->node()->collider()->set_value(ui::collider::make_shared());

    this->_update_rect_positions(this->_layout_guide_rect->region(), state_count);
    this->_update_rect_index();

    this->_rect_plane->node()
        ->observe_renderer(
            [this, pool = observing::canceller_pool::make_shared()](ui::renderer_ptr const &renderer) {
                pool->invalidate();

                if (renderer) {
                    renderer->event_manager()
                        ->observe([this](auto const &context) {
                            if (context.method == ui::event_manager::method::touch_changed) {
                                this->_update_tracking(context.event);
                            }
                        })
                        ->add_to(*pool);

                    this->_make_leave_chains()->add_to(*pool);
                    this->_make_collider_chains()->add_to(*pool);
                }
            },
            false)
        ->add_to(this->_pool);

    this->_layout_guide_rect
        ->observe([this, state_count = this->_state_count](
                      ui::region const &value) { this->_update_rect_positions(value, state_count); },
                  false)
        ->add_to(this->_pool);
}

ui::button::~button() = default;

void ui::button::set_texture(ui::texture_ptr const &texture) {
    this->rect_plane()->node()->mesh()->value()->set_texture(texture);
}

ui::texture_ptr const &ui::button::texture() const {
    return this->_rect_plane->node()->mesh()->value()->texture();
}

std::size_t ui::button::state_count() const {
    return this->_state_count;
}

void ui::button::set_state_index(std::size_t const idx) {
    if (idx >= this->_state_count) {
        throw std::invalid_argument("idx greater than or equal state count.");
    }

    this->_state_idx = idx;

    this->_update_rect_index();
}

std::size_t ui::button::state_index() const {
    return this->_state_idx;
}

void ui::button::cancel_tracking() {
    if (this->_tracking_event) {
        this->_cancel_tracking(this->_tracking_event);
    }
}

observing::canceller_ptr ui::button::observe(observing::caller<chain_pair_t>::handler_f &&handler) {
    return this->_notifier->observe(std::move(handler));
}

ui::rect_plane_ptr const &ui::button::rect_plane() {
    return this->_rect_plane;
}

ui::layout_guide_rect_ptr const &ui::button::layout_guide_rect() {
    return this->_layout_guide_rect;
}

bool ui::button::_is_tracking() {
    return !!this->_tracking_event;
}

bool ui::button::_is_tracking(ui::event_ptr const &event) {
    if (event && this->_tracking_event) {
        return *event == *this->_tracking_event;
    } else {
        return false;
    }
}

void ui::button::_set_tracking_event(ui::event_ptr const &event) {
    this->_tracking_event = event;

    this->_update_rect_index();
}

void ui::button::_update_rect_positions(ui::region const &region, std::size_t const state_count) {
    auto each = make_fast_each(state_count * 2);
    while (yas_each_next(each)) {
        this->_rect_plane->data()->set_rect_position(region, yas_each_index(each));
    }

    ui::collider_ptr const &collider = this->_rect_plane->node()->collider()->value();
    if (!collider->shape() || (collider->shape()->type_info() == typeid(ui::shape::rect))) {
        collider->set_shape(ui::shape::make_shared({.rect = region}));
    }
}

void ui::button::_update_rect_index() {
    std::size_t const idx = to_rect_index(this->_state_idx, this->_is_tracking());
    this->_rect_plane->data()->set_rect_index(0, idx);
}

observing::cancellable_ptr ui::button::_make_leave_chains() {
    ui::node_ptr const &node = this->_rect_plane->node();

    auto pool = observing::canceller_pool::make_shared();

    node->position()
        ->observe(
            [this](auto const &) {
                if (auto tracking_event = this->_tracking_event) {
                    this->_leave_or_enter_or_move_tracking(tracking_event);
                }
            },
            false)
        ->add_to(*pool);
    node->angle()
        ->observe(
            [this](auto const &) {
                if (auto tracking_event = this->_tracking_event) {
                    this->_leave_or_enter_or_move_tracking(tracking_event);
                }
            },
            false)
        ->add_to(*pool);
    node->scale()
        ->observe(
            [this](auto const &) {
                if (auto tracking_event = this->_tracking_event) {
                    this->_leave_or_enter_or_move_tracking(tracking_event);
                }
            },
            false)
        ->add_to(*pool);

    node->collider()
        ->observe(
            [this](ui::collider_ptr const &value) {
                if (!value) {
                    if (auto tracking_event = this->_tracking_event) {
                        this->_cancel_tracking(tracking_event);
                    }
                }
            },
            false)
        ->add_to(*pool);
    node->is_enabled()
        ->observe(
            [this](bool const &value) {
                if (!value) {
                    if (auto tracking_event = this->_tracking_event) {
                        this->_cancel_tracking(tracking_event);
                    }
                }
            },
            true)
        ->add_to(*pool);

    return pool;
}

observing::cancellable_ptr ui::button::_make_collider_chains() {
    auto &node = this->_rect_plane->node();

    auto pool = observing::canceller_pool::make_shared();

    node->collider()
        ->value()
        ->observe_shape(
            [this](ui::shape_ptr const &shape) {
                if (!shape) {
                    if (auto tracking_event = this->_tracking_event) {
                        this->_cancel_tracking(tracking_event);
                    }
                }
            },
            false)
        ->add_to(*pool);

    node->collider()
        ->value()
        ->observe_enabled(
            [this](bool const &enabled) {
                if (!enabled) {
                    if (auto tracking_event = this->_tracking_event) {
                        this->_cancel_tracking(tracking_event);
                    }
                }
            },
            false)
        ->add_to(*pool);

    return pool;
}

void ui::button::_update_tracking(ui::event_ptr const &event) {
    auto &node = this->_rect_plane->node();
    if (auto const renderer = node->renderer()) {
        auto const &detector = renderer->detector();

        auto const &touch_event = event->get<ui::touch>();
        switch (event->phase()) {
            case ui::event_phase::began:
                if (!this->_is_tracking()) {
                    if (detector->detect(touch_event.position(), node->collider()->value())) {
                        this->_set_tracking_event(event);
                        this->_send_notify(method::began, event);
                    }
                }
                break;
            case ui::event_phase::stationary:
            case ui::event_phase::changed: {
                this->_leave_or_enter_or_move_tracking(event);
            } break;
            case ui::event_phase::ended:
                if (this->_is_tracking(event)) {
                    auto const send_evnet = event;
                    this->_set_tracking_event(nullptr);
                    this->_send_notify(method::ended, send_evnet);
                }
                break;
            case ui::event_phase::canceled:
                this->_cancel_tracking(event);
                break;
            default:
                break;
        }
    }
}

void ui::button::_leave_or_enter_or_move_tracking(ui::event_ptr const &event) {
    auto &node = this->_rect_plane->node();
    if (auto const renderer = node->renderer()) {
        auto const &detector = renderer->detector();
        auto const &touch_event = event->get<ui::touch>();
        bool const is_event_tracking = this->_is_tracking(event);
        bool is_detected = detector->detect(touch_event.position(), node->collider()->value());
        if (!is_event_tracking && is_detected) {
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

void ui::button::_cancel_tracking(ui::event_ptr const &event) {
    if (this->_is_tracking(event)) {
        auto const send_event = event;
        this->_set_tracking_event(nullptr);
        this->_send_notify(method::canceled, send_event);
    }
}

void ui::button::_send_notify(method const method, ui::event_ptr const &event) {
    this->_notifier->notify(std::make_pair(method, context{.button = this, .touch = event->get<ui::touch>()}));
}

ui::button_ptr ui::button::make_shared(ui::region const &region) {
    return make_shared(region, 1);
}

ui::button_ptr ui::button::make_shared(ui::region const &region, std::size_t const state_count) {
    return std::shared_ptr<button>(new button{region, state_count});
}

#pragma mark -

std::size_t yas::to_rect_index(std::size_t const state_idx, bool is_tracking) {
    return state_idx * 2 + (is_tracking ? 1 : 0);
}

std::string yas::to_string(ui::button::method const &method) {
    switch (method) {
        case ui::button::method::began:
            return "began";
        case ui::button::method::entered:
            return "entered";
        case ui::button::method::moved:
            return "moved";
        case ui::button::method::leaved:
            return "leaved";
        case ui::button::method::ended:
            return "ended";
        case ui::button::method::canceled:
            return "canceled";
    }
}

std::ostream &operator<<(std::ostream &os, yas::ui::button::method const &method) {
    os << to_string(method);
    return os;
}
