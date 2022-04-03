//
//  yas_ui_touch_tracker.mm
//

#include "yas_ui_touch_tracker.h"
#include <cpp_utils/yas_fast_each.h>
#include <ui/yas_ui_detector.h>
#include <ui/yas_ui_event_manager.h>

using namespace yas;
using namespace yas::ui;

std::shared_ptr<touch_tracker> touch_tracker::make_shared(std::shared_ptr<ui::standard> const &standard,
                                                          std::shared_ptr<ui::node> const &node) {
    return make_shared(standard->detector(), standard->event_manager(), standard->renderer(), node);
}

std::shared_ptr<touch_tracker> touch_tracker::make_shared(std::shared_ptr<ui::collider_detectable> const &detector,
                                                          std::shared_ptr<ui::event_observable> const &event_observer,
                                                          std::shared_ptr<ui::renderer_observable> const &renderer,
                                                          std::shared_ptr<ui::node> const &node) {
    return std::shared_ptr<touch_tracker>(new touch_tracker{detector, event_observer, renderer, node});
}

touch_tracker::touch_tracker(std::shared_ptr<ui::collider_detectable> const &detector,
                             std::shared_ptr<ui::event_observable> const &event_observer,
                             std::shared_ptr<ui::renderer_observable> const &renderer,
                             std::shared_ptr<ui::node> const &node)
    : _weak_detector(detector), _weak_node(node), _notifier(observing::notifier<context>::make_shared()) {
    event_observer
        ->observe([this](const std::shared_ptr<ui::event> &event) {
            if (event->type() == ui::event_type::touch) {
                this->_update_tracking(event);
            }
        })
        .end()
        ->add_to(this->_pool);

    renderer->observe_will_render([this](auto const &) { this->_leave_or_enter_or_move_tracking(); })
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

void touch_tracker::set_can_begin_tracking(std::function<bool(std::shared_ptr<ui::event> const &)> &&handler) {
    this->_can_begin_tracking = std::move(handler);
}

void touch_tracker::cancel_tracking() {
    if (this->_tracking.has_value()) {
        this->_cancel_tracking(this->_tracking.value().event);
    }
}

std::optional<struct touch_tracker::tracking> const &touch_tracker::tracking() const {
    return this->_tracking;
}

observing::endable touch_tracker::observe(std::function<void(context const &)> &&handler) {
    return this->_notifier->observe(std::move(handler));
}

std::vector<std::shared_ptr<ui::collider>> const &touch_tracker::_colliders() const {
    if (auto const node = this->_weak_node.lock()) {
        return node->colliders();
    } else {
        static std::vector<std::shared_ptr<ui::collider>> const empty;
        return empty;
    }
}

void touch_tracker::_update_tracking(std::shared_ptr<ui::event> const &event) {
    if (auto const detector = this->_weak_detector.lock()) {
        auto const &touch_event = event->get<ui::touch>();
        switch (event->phase()) {
            case ui::event_phase::began:
                if (!this->_tracking.has_value()) {
                    auto each = make_fast_each(this->_colliders().size());
                    while (yas_each_next(each)) {
                        auto const &idx = yas_each_index(each);
                        if (detector->detect(touch_event.position, this->_colliders().at(idx)) &&
                            this->_can_begin_tracking_value(event)) {
                            this->_set_tracking(event, idx);
                            this->_notify(phase::began, event, idx);
                        }
                    }
                }
                break;
            case ui::event_phase::stationary:
            case ui::event_phase::changed: {
                this->_leave_or_enter_or_move_tracking(event);
            } break;
            case ui::event_phase::ended:
                if (this->_is_tracking(event, std::nullopt)) {
                    auto const ended_tracking = this->_tracking.value();
                    this->_reset_tracking();
                    this->_notify(phase::ended, ended_tracking.event, ended_tracking.collider_idx);
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

void touch_tracker::_leave_or_enter_or_move_tracking() {
    if (this->_tracking.has_value()) {
        this->_leave_or_enter_or_move_tracking(this->_tracking.value().event);
    }
}

void touch_tracker::_leave_or_enter_or_move_tracking(std::shared_ptr<ui::event> const &event) {
    if (auto const detector = this->_weak_detector.lock()) {
        auto const &touch_event = event->get<ui::touch>();

        auto each = make_fast_each(this->_colliders().size());
        while (yas_each_next(each)) {
            auto const &idx = yas_each_index(each);

            bool const is_event_tracking = this->_is_tracking(event, idx);
            bool const is_detected = detector->detect(touch_event.position, this->_colliders().at(idx));

            if (!is_event_tracking && is_detected && this->_can_begin_tracking_value(event)) {
                this->_set_tracking(event, idx);
                this->_notify(phase::entered, event, idx);
            } else if (is_event_tracking && !is_detected) {
                this->_reset_tracking();
                this->_notify(phase::leaved, event, idx);
            } else if (is_event_tracking) {
                this->_notify(phase::moved, event, idx);
            }
        }
    }
}

void touch_tracker::_cancel_tracking(std::shared_ptr<ui::event> const &event) {
    if (this->_tracking.has_value() && *this->_tracking.value().event == *event) {
        auto const canceled_tracking = this->_tracking.value();
        this->_reset_tracking();
        this->_notify(phase::canceled, canceled_tracking.event, canceled_tracking.collider_idx);
    }
}

void touch_tracker::_notify(phase const phase, std::shared_ptr<ui::event> const &event,
                            std::size_t const collider_idx) {
    auto const touch_event = event->get<ui::touch>();
    auto const &collider = this->_colliders().at(collider_idx);

    this->_notifier->notify(touch_tracker::context{.phase = phase,
                                                   .event = event,
                                                   .touch_event = touch_event,
                                                   .collider_idx = collider_idx,
                                                   .collider = collider});
}

bool touch_tracker::_is_tracking(std::shared_ptr<ui::event> const &event,
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

void touch_tracker::_set_tracking(std::shared_ptr<ui::event> const &event, std::size_t const collider_idx) {
    this->_tracking = {.event = event, .collider_idx = collider_idx};
}

void touch_tracker::_reset_tracking() {
    this->_tracking = std::nullopt;
}

bool touch_tracker::_can_begin_tracking_value(std::shared_ptr<ui::event> const &event) const {
    // ラムダ式がなければトラッキング開始できる。ラムダ式があれば、trueを返せばトラッキング開始できる
    return !this->_can_begin_tracking || (this->_can_begin_tracking && this->_can_begin_tracking(event));
}
