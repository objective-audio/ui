//
//  yas_ui_event_types.cpp
//

#include "yas_ui_event_types.h"

using namespace yas;
using namespace yas::ui;

#pragma mark - cursor_event

cursor_event::cursor_event(point pos, double const timestamp) : position(std::move(pos)), timestamp(timestamp) {
}

bool cursor_event::operator==(cursor_event const &rhs) const {
    return true;
}

bool cursor_event::operator!=(cursor_event const &rhs) const {
    return false;
}

bool cursor_event::contains_in_window() const {
    return -1.0f <= this->position.x && this->position.x <= 1.0f && -1.0f <= this->position.y &&
           this->position.y <= 1.0f;
}

#pragma mark - touch_id

bool touch_id::operator==(touch_id const &rhs) const {
    return this->kind == rhs.kind && this->identifier == rhs.identifier;
}

bool touch_id::operator!=(touch_id const &rhs) const {
    return !(*this == rhs);
}

touch_id const &touch_id::mouse_left() {
    static touch_id const _mouse_left{.kind = touch_kind::mouse, .identifier = 0};
    return _mouse_left;
}

touch_id const &touch_id::mouse_right() {
    static touch_id const _mouse_right{.kind = touch_kind::mouse, .identifier = 1};
    return _mouse_right;
}

#pragma mark - touch_event

touch_event::touch_event(touch_id const identifier, point pos, double const timestamp)
    : identifier(identifier), position(std::move(pos)), timestamp(timestamp) {
}

bool touch_event::operator==(touch_event const &rhs) const {
    return this->identifier == rhs.identifier;
}

bool touch_event::operator!=(touch_event const &rhs) const {
    return !(*this == rhs);
}

#pragma mark - key_event

key_event::key_event(uint16_t const key_code, std::string charas, std::string charas2, double const timestamp)
    : _key_code(key_code), _characters(std::move(charas)), _raw_characters(std::move(charas2)), _timestamp(timestamp) {
}

bool key_event::operator==(key_event const &rhs) const {
    return this->_key_code == rhs._key_code;
}

bool key_event::operator!=(key_event const &rhs) const {
    return !(*this == rhs);
}

uint16_t key_event::key_code() const {
    return this->_key_code;
}

std::string const &key_event::characters() const {
    return this->_characters;
}

std::string const &key_event::raw_characters() const {
    return this->_raw_characters;
}

double key_event::timestamp() const {
    return this->_timestamp;
}

#pragma mark - modifier_event

modifier_event::modifier_event(modifier_flags const flag, double const timestamp) : _flag(flag), _timestamp(timestamp) {
}

bool modifier_event::operator==(modifier_event const &rhs) const {
    return this->_flag == rhs._flag;
}

bool modifier_event::operator!=(modifier_event const &rhs) const {
    return !(*this == rhs);
}

modifier_flags modifier_event::flag() const {
    return this->_flag;
}

double modifier_event::timestamp() const {
    return this->_timestamp;
}

#pragma mark - pinch_event

pinch_event::pinch_event(double const magnification, double const timestamp)
    : _magnification(magnification), _timestamp(timestamp) {
}

bool pinch_event::operator==(pinch_event const &rhs) const {
    return this->_magnification == rhs._magnification;
}

bool pinch_event::operator!=(pinch_event const &rhs) const {
    return !(*this == rhs);
}

double pinch_event::magnification() const {
    return this->_magnification;
}

double pinch_event::timestamp() const {
    return this->_timestamp;
}

#pragma mark - scroll_event

scroll_event::scroll_event(double const x, double const y, double const timestamp)
    : _delta_x(x), _delta_y(y), _timestamp(timestamp) {
}

bool scroll_event::operator==(scroll_event const &rhs) const {
    return this->_delta_x == rhs._delta_x && this->_delta_y == rhs._delta_y;
}

bool scroll_event::operator!=(scroll_event const &rhs) const {
    return !(*this == rhs);
}

double scroll_event::deltaX() const {
    return this->_delta_x;
}

double scroll_event::deltaY() const {
    return this->_delta_y;
}

double scroll_event::timestamp() const {
    return this->_timestamp;
}

#pragma mark -

std::string yas::to_string(cursor_event const &event) {
    return "{position:" + to_string(event.position) + "}";
}

std::string yas::to_string(touch_event const &event) {
    return "{position:" + to_string(event.position) + "}";
}

std::string yas::to_string(key_event const &event) {
    return "{key_code:" + std::to_string(event.key_code()) + ", characters:" + event.characters() +
           ", raw_characters:" + event.raw_characters() + "}";
}

std::string yas::to_string(modifier_event const &event) {
    return "{flag:" + to_string(event.flag()) + "}";
}

std::string yas::to_string(ui::pinch_event const &event) {
    return "{magnification:" + std::to_string(event.magnification()) + "}";
}

std::string yas::to_string(ui::scroll_event const &event) {
    return "{x:" + std::to_string(event.deltaX()) + ", y:" + std::to_string(event.deltaY()) + "}";
}

std::string yas::to_string(event_phase const &phase) {
    switch (phase) {
        case event_phase::began:
            return "began";
        case event_phase::stationary:
            return "stationary";
        case event_phase::changed:
            return "changed";
        case event_phase::ended:
            return "ended";
        case event_phase::canceled:
            return "canceled";
        case event_phase::may_begin:
            return "may_begin";
        case event_phase::none:
            return "none";
    }
}

std::string yas::to_string(modifier_flags const &flag) {
    switch (flag) {
        case modifier_flags::alpha_shift:
            return "alpha_shift";
        case modifier_flags::shift:
            return "shift";
        case modifier_flags::control:
            return "control";
        case modifier_flags::alternate:
            return "alternate";
        case modifier_flags::command:
            return "command";
        case modifier_flags::numeric_pad:
            return "numeric_pad";
        case modifier_flags::help:
            return "help";
        case modifier_flags::function:
            return "function";
    }

    return "unknown";
}

std::string yas::to_string(ui::event_type const &type) {
    switch (type) {
        case event_type::cursor:
            return "cursor";
        case event_type::touch:
            return "touch";
        case event_type::key:
            return "key";
        case event_type::modifier:
            return "modifier";
        case event_type::pinch:
            return "pinch";
        case event_type::scroll:
            return "scroll";
    }
}

std::ostream &operator<<(std::ostream &os, yas::ui::cursor_event const &value) {
    os << to_string(value);
    return os;
}

std::ostream &operator<<(std::ostream &os, yas::ui::touch_event const &value) {
    os << to_string(value);
    return os;
}

std::ostream &operator<<(std::ostream &os, yas::ui::key_event const &value) {
    os << to_string(value);
    return os;
}

std::ostream &operator<<(std::ostream &os, yas::ui::modifier_event const &value) {
    os << to_string(value);
    return os;
}

std::ostream &operator<<(std::ostream &os, yas::ui::pinch_event const &value) {
    os << to_string(value);
    return os;
}

std::ostream &operator<<(std::ostream &os, yas::ui::scroll_event const &value) {
    os << to_string(value);
    return os;
}

std::ostream &operator<<(std::ostream &os, yas::ui::event_phase const &phase) {
    os << to_string(phase);
    return os;
}

std::ostream &operator<<(std::ostream &os, yas::ui::modifier_flags const &flags) {
    os << to_string(flags);
    return os;
}

std::ostream &operator<<(std::ostream &os, yas::ui::event_type const &event_type) {
    os << to_string(event_type);
    return os;
}
