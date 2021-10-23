//
//  yas_ui_event.cpp
//

#include "yas_ui_event.h"

#include <ui/yas_ui_types.h>

#include <unordered_map>

using namespace yas;
using namespace yas::ui;

#pragma mark - event::impl

struct ui::event_impl_base {
    virtual std::type_info const &type_info() const = 0;

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

    ~impl() {
    }

    bool is_equal(std::shared_ptr<impl> const &rhs) const {
        return this->value == rhs->value;
    }

    std::type_info const &type_info() const override {
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

event::event(pinch const &) : _pinch_impl(std::make_shared<impl<pinch>>()) {
}

event::event(scroll const &) : _scroll_impl(std::make_shared<impl<scroll>>()) {
}

event_phase event::phase() const {
    return this->_impl()->phase;
}

event_type event::type() const {
    std::type_info const &type_info = this->type_info();

    if (type_info == typeid(ui::cursor)) {
        return event_type::cursor;
    } else if (type_info == typeid(ui::touch)) {
        return event_type::touch;
    } else if (type_info == typeid(ui::key)) {
        return event_type::key;
    } else if (type_info == typeid(ui::modifier)) {
        return event_type::modifier;
    } else if (type_info == typeid(ui::pinch)) {
        return event_type::pinch;
    } else if (type_info == typeid(ui::scroll)) {
        return event_type::scroll;
    } else {
        throw std::runtime_error("invalid type_info.");
    }
}

std::type_info const &event::type_info() const {
    return this->_impl()->type_info();
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
void event::set<pinch>(pinch::type value) {
    this->_pinch_impl->value = value;
}

template <>
void event::set<scroll>(scroll::type value) {
    this->_scroll_impl->value = value;
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

template <>
pinch::type const &event::get<pinch>() const {
    return this->_pinch_impl->value;
}

template <>
scroll::type const &event::get<scroll>() const {
    return this->_scroll_impl->value;
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
    } else if (this->_pinch_impl && rhs._pinch_impl) {
        return this->_pinch_impl->is_equal(rhs._pinch_impl);
    } else if (this->_scroll_impl && rhs._scroll_impl) {
        return this->_scroll_impl->is_equal(rhs._scroll_impl);
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
    } else if (this->_pinch_impl) {
        return this->_pinch_impl;
    } else if (this->_scroll_impl) {
        return this->_scroll_impl;
    } else {
        return nullptr;
    }
}

std::shared_ptr<event> event::make_shared(cursor const &cursor) {
    return std::shared_ptr<event>(new event{cursor});
}

std::shared_ptr<event> event::make_shared(touch const &touch) {
    return std::shared_ptr<event>(new event{touch});
}

std::shared_ptr<event> event::make_shared(key const &key) {
    return std::shared_ptr<event>(new event{key});
}

std::shared_ptr<event> event::make_shared(modifier const &modifier) {
    return std::shared_ptr<event>(new event{modifier});
}

std::shared_ptr<event> event::make_shared(pinch const &pinch) {
    return std::shared_ptr<event>(new event{pinch});
}

std::shared_ptr<event> event::make_shared(scroll const &scroll) {
    return std::shared_ptr<event>(new event{scroll});
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
    } else if (event.type_info() == typeid(pinch)) {
        type = "pinch";
        values = to_string(event.get<pinch>());
    } else if (event.type_info() == typeid(scroll)) {
        type = "scroll";
        values = to_string(event.get<scroll>());
    }

    return "{phase:" + to_string(event.phase()) + ", type:" + type + ", values:" + values + "}";
}

std::ostream &operator<<(std::ostream &os, yas::ui::event const &event) {
    os << to_string(event);
    return os;
}
