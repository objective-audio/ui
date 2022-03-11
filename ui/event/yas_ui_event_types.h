//
//  yas_ui_event_types.h
//

#pragma once

#include <ui/yas_ui_types.h>

#include <string>

namespace yas::ui {
enum class event_type { cursor, touch, key, modifier, pinch, scroll };

enum class event_phase {
    none,
    began,
    stationary,
    changed,
    ended,
    canceled,
    may_begin,
};

enum modifier_flags : uint32_t {
    alpha_shift = 1 << 16,
    shift = 1 << 17,
    control = 1 << 18,
    alternate = 1 << 19,
    command = 1 << 20,
    numeric_pad = 1 << 21,
    help = 1 << 22,
    function = 1 << 23,
};

struct cursor_event final {
    cursor_event(ui::point, double const timestamp);

    bool operator==(cursor_event const &) const;
    bool operator!=(cursor_event const &) const;

    ui::point const &position() const;
    double timestamp() const;
    bool contains_in_window() const;

   private:
    ui::point _position;
    double _timestamp;
};

enum class touch_kind {
    touch,
    mouse,
};

struct touch_id final {
    touch_kind kind;
    uintptr_t identifier;

    bool operator==(touch_id const &) const;
    bool operator!=(touch_id const &) const;
};

struct touch_event final {
    touch_event(touch_id const identifier, ui::point position, double const timestamp);

    bool operator==(touch_event const &) const;
    bool operator!=(touch_event const &) const;

    touch_id identifier() const;
    ui::point const &position() const;
    double timestamp() const;

   private:
    touch_id _identifier;
    ui::point _position;
    double _timestamp;
};

struct key_event final {
    key_event(uint16_t const key_code, std::string characters, std::string raw_characters, double const timestamp);

    bool operator==(key_event const &) const;
    bool operator!=(key_event const &) const;

    uint16_t key_code() const;
    std::string const &characters() const;
    std::string const &raw_characters() const;
    double timestamp() const;

   private:
    uint16_t _key_code;
    std::string _characters;
    std::string _raw_characters;
    double _timestamp;
};

struct modifier_event final {
    modifier_event(modifier_flags const, double const timestamp);

    bool operator==(modifier_event const &) const;
    bool operator!=(modifier_event const &) const;

    modifier_flags flag() const;
    double timestamp() const;

   private:
    modifier_flags _flag;
    double _timestamp;
};

struct pinch_event final {
    pinch_event(double const magnification, double const timestamp);

    bool operator==(pinch_event const &) const;
    bool operator!=(pinch_event const &) const;

    double magnification() const;
    double timestamp() const;

   private:
    double _magnification = 0.0f;
    double _timestamp;
};

struct scroll_event final {
    scroll_event(double const x, double const y, double const timestamp);

    bool operator==(scroll_event const &) const;
    bool operator!=(scroll_event const &) const;

    double deltaX() const;
    double deltaY() const;
    double timestamp() const;

   private:
    double _delta_x = 0.0;
    double _delta_y = 0.0;
    double _timestamp;
};

struct cursor {
    using type = cursor_event;
};

struct touch {
    using type = touch_event;
};

struct key {
    using type = key_event;
};

struct modifier {
    using type = modifier_event;
};

struct pinch {
    using type = pinch_event;
};

struct scroll {
    using type = scroll_event;
};

static cursor constexpr cursor_tag{};
static touch constexpr touch_tag{};
static key constexpr key_tag{};
static modifier constexpr modifier_tag{};
static pinch constexpr pinch_tag{};
static scroll constexpr scroll_tag{};
}  // namespace yas::ui

namespace yas {
std::string to_string(ui::cursor_event const &);
std::string to_string(ui::touch_event const &);
std::string to_string(ui::key_event const &);
std::string to_string(ui::modifier_event const &);
std::string to_string(ui::pinch_event const &);
std::string to_string(ui::scroll_event const &);
std::string to_string(ui::event_phase const &);
std::string to_string(ui::modifier_flags const &);
std::string to_string(ui::event_type const &type);
}  // namespace yas

std::ostream &operator<<(std::ostream &, yas::ui::cursor_event const &);
std::ostream &operator<<(std::ostream &, yas::ui::touch_event const &);
std::ostream &operator<<(std::ostream &, yas::ui::key_event const &);
std::ostream &operator<<(std::ostream &, yas::ui::modifier_event const &);
std::ostream &operator<<(std::ostream &, yas::ui::pinch_event const &);
std::ostream &operator<<(std::ostream &, yas::ui::scroll_event const &);
std::ostream &operator<<(std::ostream &, yas::ui::event_phase const &);
std::ostream &operator<<(std::ostream &, yas::ui::modifier_flags const &);
std::ostream &operator<<(std::ostream &, yas::ui::event_type const &event_type);
