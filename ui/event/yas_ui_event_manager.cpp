//
//  yas_ui_event_manager.cpp
//

#include "yas_ui_event_manager.h"

using namespace yas;
using namespace yas::ui;

event_manager::event_manager() {
}

event_manager::~event_manager() = default;

observing::endable event_manager::observe(observing::caller<std::shared_ptr<event>>::handler_f &&handler) {
    return this->_notifier->observe(std::move(handler));
}

void event_manager::input_cursor_event(cursor_event const &value) {
    event_phase phase;

    if (value.contains_in_window()) {
        if (this->_cursor_event) {
            phase = event_phase::changed;
        } else {
            phase = event_phase::began;
            this->_cursor_event = event::make_shared(cursor_tag);
        }
    } else {
        phase = event_phase::ended;
    }

    if (this->_cursor_event) {
        this->_cursor_event->set_phase(phase);
        this->_cursor_event->set<cursor>(value);

        this->_notifier->notify(this->_cursor_event);

        if (phase == event_phase::ended) {
            this->_cursor_event = nullptr;
        }
    }
}

void event_manager::input_touch_event(event_phase const phase, touch_event const &value) {
    auto const identifer = value.identifier();

    if (phase == event_phase::began) {
        if (this->_touch_events.count(identifer) > 0) {
            return;
        }
        std::shared_ptr<event> event = event::make_shared(touch_tag);
        this->_touch_events.emplace(std::make_pair(identifer, std::move(event)));
    }

    if (this->_touch_events.count(identifer) > 0) {
        auto &event = this->_touch_events.at(identifer);
        event->set_phase(phase);
        event->set<touch>(value);

        this->_notifier->notify(event);

        if (phase == event_phase::ended || phase == event_phase::canceled) {
            this->_touch_events.erase(identifer);
        }
    }
}

void event_manager::input_key_event(event_phase const phase, key_event const &value) {
    auto const key_code = value.key_code();

    if (phase == event_phase::began) {
        if (this->_key_events.count(key_code) > 0) {
            return;
        }
        std::shared_ptr<event> event = event::make_shared(key_tag);
        this->_key_events.emplace(std::make_pair(key_code, std::move(event)));
    }

    if (this->_key_events.count(key_code) > 0) {
        auto const &event = this->_key_events.at(key_code);
        event->set_phase(phase);
        event->set<key>(value);

        this->_notifier->notify(event);

        if (phase == event_phase::ended || phase == event_phase::canceled) {
            this->_key_events.erase(key_code);
        }
    }
}

void event_manager::input_modifier_event(modifier_flags const &flags, double const timestamp) {
    static auto all_flags = {modifier_flags::alpha_shift, modifier_flags::shift,   modifier_flags::control,
                             modifier_flags::alternate,   modifier_flags::command, modifier_flags::numeric_pad,
                             modifier_flags::help,        modifier_flags::function};

    for (auto const &flag : all_flags) {
        if (flags & flag) {
            if (this->_modifier_events.count(flag) == 0) {
                std::shared_ptr<event> const event = event::make_shared(modifier_tag);
                event->set<modifier>(modifier_event{flag, timestamp});
                event->set_phase(event_phase::began);
                this->_modifier_events.emplace(std::make_pair(flag, std::move(event)));

                this->_notifier->notify(this->_modifier_events.at(flag));
            }
        } else {
            if (this->_modifier_events.count(flag) > 0) {
                auto const &event = this->_modifier_events.at(flag);
                event->set_phase(event_phase::ended);

                this->_notifier->notify(event);

                this->_modifier_events.erase(flag);
            }
        }
    }
}

std::shared_ptr<event_manager> event_manager::make_shared() {
    return std::shared_ptr<event_manager>(new event_manager{});
}
