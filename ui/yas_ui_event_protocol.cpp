//
//  yas_ui_event_protocol.cpp
//

#include "yas_ui_event_protocol.h"

using namespace yas;

#pragma mark - cursor_event

ui::cursor_event::cursor_event() : _position({.v = 0.0f}), _timestamp(0.0) {
}

ui::cursor_event::cursor_event(ui::point pos, double const timestamp)
    : _position(std::move(pos)), _timestamp(timestamp) {
}

bool ui::cursor_event::operator==(cursor_event const &rhs) const {
    return true;
}

bool ui::cursor_event::operator!=(cursor_event const &rhs) const {
    return false;
}

ui::point const &ui::cursor_event::position() const {
    return this->_position;
}

double ui::cursor_event::timestamp() const {
    return this->_timestamp;
}

bool ui::cursor_event::contains_in_window() const {
    return -1.0f <= this->_position.x && this->_position.x <= 1.0f && -1.0f <= this->_position.y &&
           this->_position.y <= 1.0f;
}

#pragma mark - touch_event

ui::touch_event::touch_event() : _identifier(-1), _position({.v = {0.0f}}) {
}

ui::touch_event::touch_event(uintptr_t const identifier, ui::point pos, double const timestamp)
    : _identifier(identifier), _position(std::move(pos)), _timestamp(timestamp) {
}

bool ui::touch_event::operator==(touch_event const &rhs) const {
    return this->_identifier == rhs._identifier;
}

bool ui::touch_event::operator!=(touch_event const &rhs) const {
    return this->_identifier != rhs._identifier;
}

uintptr_t ui::touch_event::identifier() const {
    return this->_identifier;
}

ui::point const &ui::touch_event::position() const {
    return this->_position;
}

double ui::touch_event::timestamp() const {
    return this->_timestamp;
}

#pragma mark - key_event

ui::key_event::key_event() {
}

ui::key_event::key_event(uint16_t const key_code, std::string charas, std::string charas2, double const timestamp)
    : _key_code(key_code), _characters(std::move(charas)), _raw_characters(std::move(charas2)), _timestamp(timestamp) {
}

bool ui::key_event::operator==(key_event const &rhs) const {
    return this->_key_code == rhs._key_code;
}

bool ui::key_event::operator!=(key_event const &rhs) const {
    return this->_key_code != rhs._key_code;
}

uint16_t ui::key_event::key_code() const {
    return this->_key_code;
}

std::string const &ui::key_event::characters() const {
    return this->_characters;
}

std::string const &ui::key_event::raw_characters() const {
    return this->_raw_characters;
}

double ui::key_event::timestamp() const {
    return this->_timestamp;
}

#pragma mark - modifier_event

ui::modifier_event::modifier_event() {
}

ui::modifier_event::modifier_event(modifier_flags const flag, double const timestamp)
    : _flag(flag), _timestamp(timestamp) {
}

bool ui::modifier_event::operator==(modifier_event const &rhs) const {
    return this->_flag == rhs._flag;
}

bool ui::modifier_event::operator!=(modifier_event const &rhs) const {
    return this->_flag != rhs._flag;
}

ui::modifier_flags ui::modifier_event::flag() const {
    return this->_flag;
}

double ui::modifier_event::timestamp() const {
    return this->_timestamp;
}

#pragma mark - event_inputtable

ui::event_inputtable::event_inputtable(std::shared_ptr<impl> impl) : protocol(std::move(impl)) {
}

ui::event_inputtable::event_inputtable(std::nullptr_t) : protocol(nullptr) {
}

void ui::event_inputtable::input_cursor_event(cursor_event value) {
    impl_ptr<impl>()->input_cursor_event(std::move(value));
}

void ui::event_inputtable::input_touch_event(event_phase const phase, touch_event value) {
    impl_ptr<impl>()->input_touch_event(phase, std::move(value));
}

void ui::event_inputtable::input_key_event(event_phase const phase, key_event value) {
    impl_ptr<impl>()->input_key_event(phase, std::move(std::move(value)));
}

void ui::event_inputtable::input_modifier_event(modifier_flags flag, double const timestamp) {
    impl_ptr<impl>()->input_modifier_event(std::move(flag), timestamp);
}

#pragma mark -

std::string yas::to_string(ui::cursor_event const &event) {
    return "{position:" + to_string(event.position()) + "}";
}

std::string yas::to_string(ui::touch_event const &event) {
    return "{position:" + to_string(event.position()) + "}";
}

std::string yas::to_string(ui::key_event const &event) {
    return "{key_code:" + std::to_string(event.key_code()) + ", characters:" + event.characters() +
           ", raw_characters:" + event.raw_characters() + "}";
}

std::string yas::to_string(ui::modifier_event const &event) {
    return "{flag:" + to_string(event.flag()) + "}";
}

std::string yas::to_string(ui::event_phase const &phase) {
    switch (phase) {
        case ui::event_phase::began:
            return "began";
        case ui::event_phase::stationary:
            return "stationary";
        case ui::event_phase::changed:
            return "changed";
        case ui::event_phase::ended:
            return "ended";
        case ui::event_phase::canceled:
            return "canceled";
        case ui::event_phase::may_begin:
            return "may_begin";
        case ui::event_phase::none:
            return "none";
    }
}

std::string yas::to_string(ui::modifier_flags const &flag) {
    switch (flag) {
        case ui::modifier_flags::alpha_shift:
            return "alpha_shift";
        case ui::modifier_flags::shift:
            return "shift";
        case ui::modifier_flags::control:
            return "control";
        case ui::modifier_flags::alternate:
            return "alternate";
        case ui::modifier_flags::command:
            return "command";
        case ui::modifier_flags::numeric_pad:
            return "numeric_pad";
        case ui::modifier_flags::help:
            return "help";
        case ui::modifier_flags::function:
            return "function";
    }

    return "unknown";
}

std::ostream &operator<<(std::ostream &os, yas::ui::event_phase const &phase) {
    os << to_string(phase);
    return os;
}

std::ostream &operator<<(std::ostream &os, yas::ui::modifier_flags const &flags) {
    os << to_string(flags);
    return os;
}
