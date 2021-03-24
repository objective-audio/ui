//
//  yas_ui_event.cpp
//

#include "yas_ui_event.h"

#include <unordered_map>

#include "yas_ui_types.h"

using namespace yas;
using namespace yas::ui;

#pragma mark - event::impl

struct ui::event_impl_base {
    virtual std::type_info const &type() const = 0;

    event_phase phase = event_phase::none;
};

template <typename T>
struct event::impl : event_impl_base {
    typename T::type value;

    impl() {
    }

    impl(impl const &) = delete;
    impl(impl &&) = delete;
    impl &operator=(impl const &) = delete;
    impl &operator=(impl &&) = delete;

    ~impl() = default;

    bool is_equal(std::shared_ptr<impl> const &rhs) const {
        return this->value == rhs->value;
    }

    std::type_info const &type() const override {
        return typeid(T);
    }
};

#pragma mark - event

event::event(cursor const &) : _cursor_impl(std::make_shared<impl<cursor>>()) {
}

event::event(touch const &) : _touch_impl(std::make_shared<impl<touch>>()) {
}

event::event(key const &) : _key_impl(std::make_shared<impl<key>>()) {
}

event::event(modifier const &) : _modifier_impl(std::make_shared<impl<modifier>>()) {
}

event_phase event::phase() const {
    return this->_impl()->phase;
}

std::type_info const &event::type_info() const {
    return this->_impl()->type();
}

template <>
void event::set<cursor>(cursor::type value) {
    this->_cursor_impl->value = value;
}
template <>
void event::set<touch>(touch::type value) {
    this->_touch_impl->value = value;
}
template <>
void event::set<key>(key::type value) {
    this->_key_impl->value = value;
}
template <>
void event::set<modifier>(modifier::type value) {
    this->_modifier_impl->value = value;
}

template <>
cursor::type const &event::get<cursor>() const {
    return this->_cursor_impl->value;
}

template <>
touch::type const &event::get<touch>() const {
    return this->_touch_impl->value;
}

template <>
key::type const &event::get<key>() const {
    return this->_key_impl->value;
}

template <>
modifier::type const &event::get<modifier>() const {
    return this->_modifier_impl->value;
}

uintptr_t event::identifier() const {
    return reinterpret_cast<uintptr_t>(this);
}

bool event::operator==(event const &rhs) const {
    if (this->_cursor_impl && rhs._cursor_impl) {
        return this->_cursor_impl->is_equal(rhs._cursor_impl);
    } else if (this->_touch_impl && rhs._touch_impl) {
        return this->_touch_impl->is_equal(rhs._touch_impl);
    } else if (this->_key_impl && rhs._key_impl) {
        return this->_key_impl->is_equal(rhs._key_impl);
    } else if (this->_modifier_impl && rhs._modifier_impl) {
        return this->_modifier_impl->is_equal(rhs._modifier_impl);
    } else {
        return false;
    }
}

bool event::operator!=(event const &rhs) const {
    return !(*this == rhs);
}

void event::set_phase(event_phase const &phase) {
    this->_impl()->phase = std::move(phase);
}

std::shared_ptr<event_impl_base> event::_impl() const {
    if (this->_cursor_impl) {
        return this->_cursor_impl;
    } else if (this->_touch_impl) {
        return this->_touch_impl;
    } else if (this->_key_impl) {
        return this->_key_impl;
    } else if (this->_modifier_impl) {
        return this->_modifier_impl;
    } else {
        return nullptr;
    }
}

event_ptr event::make_shared(cursor const &cursor) {
    return std::shared_ptr<event>(new event{cursor});
}

event_ptr event::make_shared(touch const &touch) {
    return std::shared_ptr<event>(new event{touch});
}

event_ptr event::make_shared(key const &key) {
    return std::shared_ptr<event>(new event{key});
}

event_ptr event::make_shared(modifier const &modifier) {
    return std::shared_ptr<event>(new event{modifier});
}

#pragma mark - event_manager

event_manager::event_manager() {
}

event_manager::~event_manager() = default;

observing::canceller_ptr event_manager::observe(observing::caller<context>::handler_f &&handler) {
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

        this->_notifier->notify({.method = event_manager::method::cursor_changed, .event = this->_cursor_event});

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
        event_ptr event = event::make_shared(touch_tag);
        this->_touch_events.emplace(std::make_pair(identifer, std::move(event)));
    }

    if (this->_touch_events.count(identifer) > 0) {
        auto &event = this->_touch_events.at(identifer);
        event->set_phase(phase);
        event->set<touch>(value);

        this->_notifier->notify({.method = event_manager::method::touch_changed, .event = event});

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
        event_ptr event = event::make_shared(key_tag);
        this->_key_events.emplace(std::make_pair(key_code, std::move(event)));
    }

    if (this->_key_events.count(key_code) > 0) {
        auto const &event = this->_key_events.at(key_code);
        event->set_phase(phase);
        event->set<key>(value);

        this->_notifier->notify({.method = event_manager::method::key_changed, .event = event});

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
                event_ptr const event = event::make_shared(modifier_tag);
                event->set<modifier>(modifier_event{flag, timestamp});
                event->set_phase(event_phase::began);
                this->_modifier_events.emplace(std::make_pair(flag, std::move(event)));

                this->_notifier->notify(
                    {.method = event_manager::method::modifier_changed, .event = this->_modifier_events.at(flag)});
            }
        } else {
            if (this->_modifier_events.count(flag) > 0) {
                auto const &event = this->_modifier_events.at(flag);
                event->set_phase(event_phase::ended);

                this->_notifier->notify({.method = event_manager::method::modifier_changed, .event = event});

                this->_modifier_events.erase(flag);
            }
        }
    }
}

event_manager_ptr event_manager::make_shared() {
    return std::shared_ptr<event_manager>(new event_manager{});
}

#pragma mark -

std::string yas::to_string(event const &event) {
    std::string type = "unknown";
    std::string values;

    if (event.type_info() == typeid(cursor)) {
        type = "cursor";
        values = to_string(event.get<cursor>());
    } else if (event.type_info() == typeid(touch)) {
        type = "touch";
        values = to_string(event.get<touch>());
    } else if (event.type_info() == typeid(key)) {
        type = "key";
        values = to_string(event.get<key>());
    } else if (event.type_info() == typeid(modifier)) {
        type = "modifier";
        values = to_string(event.get<modifier>());
    }

    return "{phase:" + to_string(event.phase()) + ", type:" + type + ", values:" + values + "}";
}

std::string yas::to_string(event_manager::method const &method) {
    switch (method) {
        case event_manager::method::cursor_changed:
            return "cursor_changed";
        case event_manager::method::touch_changed:
            return "touch_changed";
        case event_manager::method::key_changed:
            return "key_changed";
        case event_manager::method::modifier_changed:
            return "modifier_changed";
    }
}

std::ostream &operator<<(std::ostream &os, yas::ui::event const &event) {
    os << to_string(event);
    return os;
}

std::ostream &operator<<(std::ostream &os, yas::ui::event_manager::method const &method) {
    os << to_string(method);
    return os;
}
