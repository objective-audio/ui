//
//  yas_ui_multiple_touch.mm
//

#include "yas_ui_multiple_touch.h"

#include <CoreFoundation/CoreFoundation.h>
#include <ui/touch_tracker/yas_ui_touch_tracker_types.h>

using namespace yas;
using namespace yas::ui;

std::shared_ptr<multiple_touch> multiple_touch::make_shared(
    std::size_t const required_count, double const max_interval,
    std::shared_ptr<system_time_providable> const &system_time_provider) {
    return std::shared_ptr<multiple_touch>(new multiple_touch{required_count, max_interval, system_time_provider});
}

multiple_touch::multiple_touch(std::size_t const required_count, double const max_interval,
                               std::shared_ptr<system_time_providable> const &system_time_provider)
    : _required_count(required_count),
      _max_interval(max_interval),
      _system_time_provider(system_time_provider),
      _notifier(observing::notifier<uintptr_t>::make_shared()) {
    assert(required_count > 1);
    assert(max_interval > 0);
}

void multiple_touch::handle_event(touch_tracker_phase const phase, uintptr_t const identifier) {
    switch (phase) {
        case touch_tracker_phase::ended: {
            auto const timestamp = this->_system_time_provider->now();

            if (this->_can_increment(identifier, timestamp)) {
                auto const count = this->_tapped.value().count + 1;
                if (count == this->_required_count) {
                    this->_tapped = std::nullopt;
                    this->_notifier->notify(identifier);
                } else {
                    this->_tapped = {.timepoint = timestamp, .count = count, .identifier = identifier};
                }
            } else {
                this->_tapped = {.timepoint = timestamp, .count = 1, .identifier = identifier};
            }
        } break;
        case touch_tracker_phase::canceled:
        case touch_tracker_phase::leaved: {
            this->_tapped = std::nullopt;
        } break;
        case touch_tracker_phase::began:
        case touch_tracker_phase::entered:
        case touch_tracker_phase::moved:
            break;
    }
}

bool multiple_touch::_can_increment(uintptr_t const identifier, time_point_t const &timestamp) {
    if (this->_tapped.has_value()) {
        auto const &prev_tapped = this->_tapped.value();
        if (prev_tapped.identifier == identifier && (timestamp < prev_tapped.timepoint + this->_max_interval)) {
            return true;
        }
    }
    return false;
}

observing::endable multiple_touch::observe(std::function<void(uintptr_t const &)> &&handler) {
    return this->_notifier->observe(std::move(handler));
}
