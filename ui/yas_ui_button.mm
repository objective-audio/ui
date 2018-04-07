//
//  yas_ui_button.mm
//

#include "yas_fast_each.h"
#include "yas_observing.h"
#include "yas_ui_button.h"
#include "yas_ui_collider.h"
#include "yas_ui_detector.h"
#include "yas_ui_event.h"
#include "yas_ui_layout_guide.h"
#include "yas_ui_mesh.h"
#include "yas_ui_node.h"
#include "yas_ui_rect_plane.h"
#include "yas_ui_renderer.h"

using namespace yas;

#pragma mark - ui::button::impl

struct ui::button::impl : base::impl {
    impl(ui::region const &region, std::size_t const state_count)
        : _rect_plane(state_count * 2, 1), _layout_guide_rect(region), _state_count(state_count) {
        this->_rect_plane.node().set_collider(ui::collider{});

        this->_update_rect_positions(this->_layout_guide_rect.region(), state_count);
        this->_update_rect_index();
    }

    void prepare(ui::button &button) {
        auto const weak_button = to_weak(button);
        auto &node = this->_rect_plane.node();

        this->_renderer_observer = node.dispatch_and_make_observer(ui::node::method::renderer_changed, [
            event_observer = base{nullptr}, leave_observer = base{nullptr}, collider_observer = base{nullptr},
            weak_button
        ](auto const &context) mutable {
            ui::node const &node = context.value;

            if (auto renderer = node.renderer()) {
                event_observer = renderer.event_manager().subject().make_observer(
                    ui::event_manager::method::touch_changed, [weak_button](auto const &context) {
                        if (auto button = weak_button.lock()) {
                            button.impl_ptr<impl>()->_update_tracking(context.value);
                        }
                    });

                if (auto button = weak_button.lock()) {
                    leave_observer = button.impl_ptr<impl>()->_make_leave_observer();
                    collider_observer = button.impl_ptr<impl>()->_make_collider_observer();
                }
            } else {
                event_observer = nullptr;
                leave_observer = nullptr;
                collider_observer = nullptr;
            }
        });

        this->_layout_guide_rect.set_value_changed_handler(
            [weak_button, state_count = this->_state_count](auto const &context) {
                if (auto button = weak_button.lock()) {
                    button.impl_ptr<impl>()->_update_rect_positions(context.new_value, state_count);
                }
            });
    }

    void set_state_idx(std::size_t const idx) {
        if (idx >= this->_state_count) {
            throw std::invalid_argument("idx greater than or equal state count.");
        }

        this->_state_idx = idx;

        this->_update_rect_index();
    }

    bool is_tracking() {
        return !!this->_tracking_event;
    }

    bool is_tracking(ui::event const &event) {
        return event == this->_tracking_event;
    }

    void set_tracking_event(ui::event event) {
        this->_tracking_event = std::move(event);

        this->_update_rect_index();
    }

    void cancel_tracking() {
        if (this->_tracking_event) {
            this->_cancel_tracking(this->_tracking_event);
        }
    }

    ui::rect_plane _rect_plane;
    ui::layout_guide_rect _layout_guide_rect;
    ui::button::subject_t _subject;
    std::size_t _state_idx = 0;
    std::size_t _state_count;

   private:
    void _update_rect_positions(ui::region const &region, std::size_t const state_count) {
        auto each = make_fast_each(state_count * 2);
        while (yas_each_next(each)) {
            this->_rect_plane.data().set_rect_position(region, yas_each_index(each));
        }

        this->_rect_plane.node().collider().set_shape(ui::shape{{.rect = region}});
    }

    void _update_rect_index() {
        std::size_t const idx = to_rect_index(this->_state_idx, this->is_tracking());
        this->_rect_plane.data().set_rect_index(0, idx);
    }

    base _make_leave_observer() {
        std::vector<ui::node::method> methods{ui::node::method::position_changed, ui::node::method::angle_changed,
                                              ui::node::method::scale_changed, ui::node::method::collider_changed,
                                              ui::node::method::enabled_changed};

        return this->_rect_plane.node().dispatch_and_make_wild_card_observer(
            methods, [weak_button = to_weak(cast<ui::button>())](auto const &context) {
                if (auto node = weak_button.lock()) {
                    if (auto const &tracking_event = node.impl_ptr<impl>()->_tracking_event) {
                        ui::node::method const &method = context.key;
                        switch (method) {
                            case ui::node::method::position_changed:
                            case ui::node::method::angle_changed:
                            case ui::node::method::scale_changed: {
                                node.impl_ptr<impl>()->_leave_or_enter_or_move_tracking(tracking_event);
                            } break;
                            case ui::node::method::collider_changed: {
                                ui::node const &node = context.value;
                                if (!node.collider()) {
                                    node.impl_ptr<impl>()->_cancel_tracking(tracking_event);
                                }
                            } break;
                            case ui::node::method::enabled_changed: {
                                ui::node const &node = context.value;
                                if (!node.is_enabled()) {
                                    node.impl_ptr<impl>()->_cancel_tracking(tracking_event);
                                }
                            } break;

                            default:
                                break;
                        }
                    }
                }
            });
    }

    base _make_collider_observer() {
        auto &node = this->_rect_plane.node();

        return node.collider().subject().make_wild_card_observer([weak_node = to_weak(node)](auto const &context) {
            if (auto node = weak_node.lock()) {
                if (auto const &tracking_event = node.impl_ptr<impl>()->_tracking_event) {
                    ui::collider::method const &method = context.key;
                    switch (method) {
                        case ui::collider::method::shape_changed: {
                            if (!node.collider().shape()) {
                                node.impl_ptr<impl>()->_cancel_tracking(tracking_event);
                            }
                        } break;
                        case ui::collider::method::enabled_changed: {
                            if (!node.collider().is_enabled()) {
                                node.impl_ptr<impl>()->_cancel_tracking(tracking_event);
                            }
                        } break;
                    }
                }
            }
        });
    }

    void _update_tracking(ui::event const &event) {
        auto &node = this->_rect_plane.node();
        if (auto renderer = node.renderer()) {
            auto const &detector = renderer.detector();
            auto button = cast<ui::button>();

            auto const &touch_event = event.get<ui::touch>();
            switch (event.phase()) {
                case ui::event_phase::began:
                    if (!this->is_tracking()) {
                        if (detector.detect(touch_event.position(), node.collider())) {
                            this->set_tracking_event(event);
                            this->_subject.notify(ui::button::method::began, {.button = button, .touch = touch_event});
                        }
                    }
                    break;
                case ui::event_phase::stationary:
                case ui::event_phase::changed: {
                    this->_leave_or_enter_or_move_tracking(event);
                } break;
                case ui::event_phase::ended:
                    if (this->is_tracking(event)) {
                        this->set_tracking_event(nullptr);
                        this->_subject.notify(ui::button::method::ended, {.button = button, .touch = touch_event});
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

    void _leave_or_enter_or_move_tracking(ui::event const &event) {
        auto &node = this->_rect_plane.node();
        if (auto renderer = node.renderer()) {
            auto const &detector = renderer.detector();
            auto const &touch_event = event.get<ui::touch>();
            bool const is_event_tracking = this->is_tracking(event);
            bool is_detected = detector.detect(touch_event.position(), node.collider());
            auto button = cast<ui::button>();
            if (!is_event_tracking && is_detected) {
                this->set_tracking_event(event);
                this->_subject.notify(ui::button::method::entered, {.button = button, .touch = touch_event});
            } else if (is_event_tracking && !is_detected) {
                this->set_tracking_event(nullptr);
                this->_subject.notify(ui::button::method::leaved, {.button = button, .touch = touch_event});
            } else if (is_event_tracking) {
                this->_subject.notify(ui::button::method::moved, {.button = button, .touch = touch_event});
            }
        }
    }

    void _cancel_tracking(ui::event const &event) {
        if (this->is_tracking(event)) {
            this->set_tracking_event(nullptr);
            this->_subject.notify(ui::button::method::canceled,
                                  {.button = cast<ui::button>(), .touch = event.get<ui::touch>()});
        }
    }

    ui::node::observer_t _renderer_observer = nullptr;
    ui::event _tracking_event = nullptr;
};

#pragma mark - ui::button

ui::button::button(ui::region const &region) : button(region, 1) {
}

ui::button::button(ui::region const &region, std::size_t const state_count)
    : base(std::make_shared<impl>(region, state_count)) {
    impl_ptr<impl>()->prepare(*this);
}

ui::button::button(std::nullptr_t) : base(nullptr) {
}

ui::button::~button() = default;

std::size_t ui::button::state_count() const {
    return impl_ptr<impl>()->_state_count;
}

void ui::button::set_state_index(std::size_t const idx) {
    impl_ptr<impl>()->set_state_idx(idx);
}

std::size_t ui::button::state_index() const {
    return impl_ptr<impl>()->_state_idx;
}

void ui::button::cancel_tracking() {
    impl_ptr<impl>()->cancel_tracking();
}

ui::button::subject_t &ui::button::subject() {
    return impl_ptr<impl>()->_subject;
}

ui::rect_plane &ui::button::rect_plane() {
    return impl_ptr<impl>()->_rect_plane;
}

ui::layout_guide_rect &ui::button::layout_guide_rect() {
    return impl_ptr<impl>()->_layout_guide_rect;
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
