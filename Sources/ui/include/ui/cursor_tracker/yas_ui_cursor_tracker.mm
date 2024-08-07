#include "yas_ui_cursor_tracker.hpp"
#include <cpp-utils/fast_each.h>
#include <ui/detector/yas_ui_detector.h>
#include <ui/event/yas_ui_event_manager.h>

using namespace yas;
using namespace yas::ui;

std::shared_ptr<cursor_tracker> cursor_tracker::make_shared(std::shared_ptr<ui::standard> const &standard,
                                                            std::shared_ptr<ui::node> const &node) {
    return make_shared(standard->detector(), standard->event_manager(), standard->renderer(), node);
}

std::shared_ptr<cursor_tracker> cursor_tracker::make_shared(std::shared_ptr<ui::collider_detectable> const &detector,
                                                            std::shared_ptr<ui::event_observable> const &event_observer,
                                                            std::shared_ptr<ui::renderer_observable> const &renderer,
                                                            std::shared_ptr<ui::node> const &node) {
    return std::shared_ptr<cursor_tracker>(new cursor_tracker{detector, event_observer, renderer, node});
}

cursor_tracker::cursor_tracker(std::shared_ptr<ui::collider_detectable> const &detector,
                               std::shared_ptr<ui::event_observable> const &event_observer,
                               std::shared_ptr<ui::renderer_observable> const &renderer,
                               std::shared_ptr<ui::node> const &node)
    : _weak_detector(detector), _weak_node(node), _notifier(observing::notifier<context>::make_shared()) {
    event_observer
        ->observe([this](const std::shared_ptr<ui::event> &event) {
            if (event->type() == ui::event_type::cursor) {
                this->_update_tracking(event);
            }
        })
        .end()
        ->add_to(this->_pool);

    renderer
        ->observe_will_render([this](auto const &) {
            if (this->_tracking.has_value()) {
                this->_leave_or_enter_or_move_tracking(this->_tracking.value().event, false);
            }
        })
        .end()
        ->add_to(this->_pool);

    node->observe_colliders([this](auto const &) { this->cancel_tracking(); }).end()->add_to(this->_pool);
    node->observe_is_enabled([this](bool const &value) {
            if (!value) {
                this->cancel_tracking();
            }
        })
        .sync()
        ->add_to(this->_pool);
}

void cursor_tracker::cancel_tracking() {
    if (this->_tracking.has_value()) {
        this->_cancel_tracking(this->_tracking.value().event);
    }
}

std::optional<struct cursor_tracker::tracking_value> const &cursor_tracker::tracking() const {
    return this->_tracking;
}

observing::endable cursor_tracker::observe(std::function<void(context const &)> &&handler) {
    return this->_notifier->observe(std::move(handler));
}

std::vector<std::shared_ptr<ui::collider>> const &cursor_tracker::_colliders() const {
    if (auto const node = this->_weak_node.lock()) {
        return node->colliders();
    } else {
        static std::vector<std::shared_ptr<ui::collider>> const empty;
        return empty;
    }
}

void cursor_tracker::_update_tracking(std::shared_ptr<ui::event> const &event) {
    if (auto const detector = this->_weak_detector.lock()) {
        auto const &cursor_event = event->get<ui::cursor>();
        switch (event->phase()) {
            case ui::event_phase::began:
                if (!this->_tracking.has_value()) {
                    auto each = make_fast_each(this->_colliders().size());
                    while (yas_each_next(each)) {
                        auto const &idx = yas_each_index(each);
                        if (detector->detect(cursor_event.position, this->_colliders().at(idx))) {
                            this->_set_tracking(event, idx);
                            this->_notify(phase::entered, event, idx);
                        }
                    }
                }
                break;
            case ui::event_phase::stationary:
            case ui::event_phase::changed: {
                this->_leave_or_enter_or_move_tracking(event, true);
            } break;
            case ui::event_phase::ended:
                if (this->_is_tracking(event, std::nullopt)) {
                    auto const ended_tracking = this->_tracking.value();
                    this->_reset_tracking();
                    this->_notify(phase::leaved, ended_tracking.event, ended_tracking.collider_idx);
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

void cursor_tracker::_leave_or_enter_or_move_tracking(std::shared_ptr<ui::event> const &event, bool needs_move) {
    if (auto const detector = this->_weak_detector.lock()) {
        auto const &cursor_event = event->get<ui::cursor>();

        auto each = make_fast_each(this->_colliders().size());
        while (yas_each_next(each)) {
            auto const &idx = yas_each_index(each);

            bool const is_event_tracking = this->_is_tracking(event, idx);
            bool const is_detected = detector->detect(cursor_event.position, this->_colliders().at(idx));

            if (!is_event_tracking && is_detected) {
                this->_set_tracking(event, idx);
                this->_notify(phase::entered, event, idx);
            } else if (is_event_tracking && !is_detected) {
                this->_reset_tracking();
                this->_notify(phase::leaved, event, idx);
            } else if (is_event_tracking && needs_move) {
                this->_notify(phase::moved, event, idx);
            }
        }
    }
}

void cursor_tracker::_cancel_tracking(std::shared_ptr<ui::event> const &event) {
    if (this->_tracking.has_value() && *this->_tracking.value().event == *event) {
        auto const canceled_tracking = this->_tracking.value();
        this->_reset_tracking();
        this->_notify(phase::leaved, canceled_tracking.event, canceled_tracking.collider_idx);
    }
}

void cursor_tracker::_notify(phase const phase, std::shared_ptr<ui::event> const &event,
                             std::size_t const collider_idx) {
    auto const cursor_event = event->get<ui::cursor>();
    auto const &collider = this->_colliders().at(collider_idx);

    this->_notifier->notify(cursor_tracker::context{.phase = phase,
                                                    .event = event,
                                                    .cursor_event = cursor_event,
                                                    .collider_idx = collider_idx,
                                                    .collider = collider});
}

bool cursor_tracker::_is_tracking(std::shared_ptr<ui::event> const &event,
                                  std::optional<std::size_t> const collider_idx) const {
    if (event && this->_tracking.has_value()) {
        // collider_idxが指定されていれば、一致していた場合のみ判定する
        if (collider_idx.has_value() && collider_idx.value() != this->_tracking.value().collider_idx) {
            return false;
        }

        return *event == *this->_tracking.value().event;
    } else {
        return false;
    }
}

void cursor_tracker::_set_tracking(std::shared_ptr<ui::event> const &event, std::size_t const collider_idx) {
    this->_tracking = {.event = event, .collider_idx = collider_idx};
}

void cursor_tracker::_reset_tracking() {
    this->_tracking = std::nullopt;
}
