//
//  yas_ui_event_protocol.cpp
//

#include "yas_ui_event_protocol.h"

using namespace yas;

#pragma mark - cursor_event

ui::cursor_event::cursor_event() : _position(0.0f) {
}

ui::cursor_event::cursor_event(simd::float2 pos) : _position(std::move(pos)) {
}

bool ui::cursor_event::operator==(cursor_event const &rhs) const {
    return true;
}

bool ui::cursor_event::operator!=(cursor_event const &rhs) const {
    return false;
}

simd::float2 const &ui::cursor_event::position() const {
    return _position;
}

bool ui::cursor_event::contains_in_window() const {
    return -1.0f <= _position.x && _position.x <= 1.0f && -1.0f <= _position.y && _position.y <= 1.0f;
}

#pragma mark - touch_event

ui::touch_event::touch_event() : _identifier(-1), _position(0.0f) {
}

ui::touch_event::touch_event(uintptr_t const identifier, simd::float2 pos)
    : _identifier(identifier), _position(std::move(pos)) {
}

bool ui::touch_event::operator==(touch_event const &rhs) const {
    return _identifier == rhs._identifier;
}

bool ui::touch_event::operator!=(touch_event const &rhs) const {
    return _identifier != rhs._identifier;
}

uintptr_t ui::touch_event::identifier() const {
    return _identifier;
}

simd::float2 const &ui::touch_event::position() const {
    return _position;
}

#pragma mark - key_event

ui::key_event::key_event() {
}

ui::key_event::key_event(uint16_t const key_code, std::string charas, std::string charas2)
    : _key_code(key_code), _characters(std::move(charas)), _characters_ignoring_modifiers(std::move(charas2)) {
}

bool ui::key_event::operator==(key_event const &rhs) const {
    return _key_code == rhs._key_code;
}

bool ui::key_event::operator!=(key_event const &rhs) const {
    return _key_code != rhs._key_code;
}

uint16_t ui::key_event::key_code() const {
    return _key_code;
}

std::string const &ui::key_event::characters() const {
    return _characters;
}

std::string const &ui::key_event::characters_ignoring_modifiers() const {
    return _characters_ignoring_modifiers;
}

#pragma mark - modifier_event

ui::modifier_event::modifier_event() {
}

ui::modifier_event::modifier_event(modifier_flags const flag) : _flag(flag) {
}

bool ui::modifier_event::operator==(modifier_event const &rhs) const {
    return _flag == rhs._flag;
}

bool ui::modifier_event::operator!=(modifier_event const &rhs) const {
    return _flag != rhs._flag;
}

ui::modifier_flags ui::modifier_event::flag() const {
    return _flag;
}

#pragma mark - event_inputtable

ui::event_inputtable::event_inputtable(std::shared_ptr<impl> impl) : protocol(std::move(impl)) {
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

void ui::event_inputtable::input_modifier_event(modifier_flags flag) {
    impl_ptr<impl>()->input_modifier_event(std::move(flag));
}

#pragma mark -

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
