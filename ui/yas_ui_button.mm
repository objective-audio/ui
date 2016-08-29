//
//  yas_ui_button.mm
//

#include "yas_each_index.h"
#include "yas_observing.h"
#include "yas_ui_button.h"
#include "yas_ui_collider.h"
#include "yas_ui_detector.h"
#include "yas_ui_event.h"
#include "yas_ui_mesh.h"
#include "yas_ui_node.h"
#include "yas_ui_rect_plane.h"
#include "yas_ui_renderer.h"

using namespace yas;

#pragma mark - ui::button::impl

struct ui::button::impl : base::impl {
    impl(ui::float_region const &region) {
        _setup(region);
    }

    void prepare(ui::button &ext) {
        auto &node = _rect_plane_ext.node();

        node.dispatch_method(ui::node::method::renderer_changed);

        _renderer_observer = node.subject().make_observer(
            ui::node::method::renderer_changed,
            [event_observer = base{nullptr}, leave_observer = base{nullptr}, weak_button_ext = to_weak(ext)](
                auto const &context) mutable {
                ui::node const &node = context.value;

                if (auto renderer = node.renderer()) {
                    event_observer = renderer.event_manager().subject().make_observer(
                        ui::event_manager::method::touch_changed, [weak_button_ext](auto const &context) {
                            if (auto button_ext = weak_button_ext.lock()) {
                                button_ext.impl_ptr<impl>()->_update_tracking(context.value);
                            }
                        });

                    if (auto button_ext = weak_button_ext.lock()) {
                        leave_observer = button_ext.impl_ptr<impl>()->_make_leave_observer();
                    }
                } else {
                    event_observer = nullptr;
                    leave_observer = nullptr;
                }
            });
    }

    void set_state(ui::button::state const &state, bool const enabled) {
        if (enabled) {
            _states.set(state);
        } else {
            _states.reset(state);
        }

        _update_rect_index();
    }

    bool is_tracking() {
        return !!_tracking_event;
    }

    bool is_tracking(ui::event const &event) {
        return event == _tracking_event;
    }

    void set_tracking_event(ui::event event) {
        _tracking_event = std::move(event);

        set_state(ui::button::state::press, !!_tracking_event);
    }

    states_t _states;
    ui::rect_plane _rect_plane_ext = ui::make_rect_plane(ui::button::state_count * 2, 1);
    ui::button::subject_t _subject;

   private:
    void _setup(ui::float_region const &region) {
        _states.flags.reset();

        for (auto const &idx : make_each(ui::button::state_count * 2)) {
            _rect_plane_ext.data().set_rect_position(region, idx);
        }

        ui::collider collider{ui::shape{{.rect = region}}};
        _rect_plane_ext.node().set_collider(std::move(collider));

        _update_rect_index();
    }

    void _update_rect_index() {
        _rect_plane_ext.data().set_rect_index(0, to_index(_states));
    }

    base _make_leave_observer() {
        auto &node = _rect_plane_ext.node();

        node.dispatch_method(ui::node::method::position_changed);
        node.dispatch_method(ui::node::method::angle_changed);
        node.dispatch_method(ui::node::method::scale_changed);
        node.dispatch_method(ui::node::method::collider_changed);
        node.dispatch_method(ui::node::method::enabled_changed);

        return node.subject().make_wild_card_observer([weak_button_ext =
                                                           to_weak(cast<ui::button>())](auto const &context) {
            if (auto node = weak_button_ext.lock()) {
                if (auto const &tracking_event = node.impl_ptr<impl>()->_tracking_event) {
                    ui::node::method const &method = context.key;
                    switch (method) {
                        case ui::node::method::position_changed:
                        case ui::node::method::angle_changed:
                        case ui::node::method::scale_changed: {
                            node.impl_ptr<impl>()->_leave_or_enter_tracking(tracking_event);
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

    void _update_tracking(ui::event const &event) {
        auto &node = _rect_plane_ext.node();
        if (auto renderer = node.renderer()) {
            auto const &detector = renderer.detector();
            auto button = cast<ui::button>();

            auto const &touch_event = event.get<ui::touch>();
            switch (event.phase()) {
                case ui::event_phase::began:
                    if (!is_tracking()) {
                        if (detector.detect(touch_event.position(), node.collider())) {
                            set_tracking_event(event);
                            _subject.notify(ui::button::method::began, button);
                        }
                    }
                    break;
                case ui::event_phase::stationary:
                case ui::event_phase::changed: {
                    _leave_or_enter_tracking(event);
                } break;
                case ui::event_phase::ended:
                    if (is_tracking(event)) {
                        set_tracking_event(nullptr);
                        _subject.notify(ui::button::method::ended, button);
                    }
                    break;
                case ui::event_phase::canceled:
                    _cancel_tracking(event);
                    break;
                default:
                    break;
            }
        }
    }

    void _leave_or_enter_tracking(ui::event const &event) {
        auto &node = _rect_plane_ext.node();
        if (auto renderer = node.renderer()) {
            auto const &detector = renderer.detector();
            auto const &touch_event = event.get<ui::touch>();
            bool const is_event_tracking = is_tracking(event);
            bool is_detected = detector.detect(touch_event.position(), node.collider());
            if (!is_event_tracking && is_detected) {
                set_tracking_event(event);
                _subject.notify(ui::button::method::entered, cast<ui::button>());
            } else if (is_event_tracking && !is_detected) {
                set_tracking_event(nullptr);
                _subject.notify(ui::button::method::leaved, cast<ui::button>());
            }
        }
    }

    void _cancel_tracking(ui::event const &event) {
        if (is_tracking(event)) {
            set_tracking_event(nullptr);
            _subject.notify(ui::button::method::canceled, cast<ui::button>());
        }
    }

    ui::node::observer_t _renderer_observer = nullptr;
    ui::event _tracking_event = nullptr;
};

#pragma mark - ui::button

ui::button::button(ui::float_region const &region) : base(std::make_shared<impl>(region)) {
    impl_ptr<impl>()->prepare(*this);
}

ui::button::button(std::nullptr_t) : base(nullptr) {
}

ui::button::~button() = default;

ui::button::subject_t &ui::button::subject() {
    return impl_ptr<impl>()->_subject;
}

ui::rect_plane &ui::button::rect_plane() {
    return impl_ptr<impl>()->_rect_plane_ext;
}

#pragma mark -

std::size_t yas::to_index(ui::button::states_t const &states) {
    std::size_t rect_idx = 0;

    if (states.test(ui::button::state::press)) {
        rect_idx += 1;
    }

    if (states.test(ui::button::state::toggle)) {
        rect_idx += ui::button::state_count;
    }

    return rect_idx;
}

std::string yas::to_string(ui::button::state const &state) {
    switch (state) {
        case ui::button::state::toggle:
            return "toggle";
        case ui::button::state::press:
            return "press";
        case ui::button::state::count:
            return "count";
    }
}

std::string yas::to_string(ui::button::method const &method) {
    switch (method) {
        case ui::button::method::began:
            return "began";
        case ui::button::method::entered:
            return "entered";
        case ui::button::method::leaved:
            return "leaved";
        case ui::button::method::ended:
            return "ended";
        case ui::button::method::canceled:
            return "canceled";
    }
}

std::ostream &operator<<(std::ostream &os, yas::ui::button::state const &state) {
    os << to_string(state);
    return os;
}

std::ostream &operator<<(std::ostream &os, yas::ui::button::method const &method) {
    os << to_string(method);
    return os;
}