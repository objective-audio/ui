//
//  yas_ui_event_types.h
//

#pragma once

#include <ui/yas_ui_types.h>

#include <string>

namespace yas::ui {
enum class event_type { cursor, touch, key, modifier };

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

struct cursor_event {
    cursor_event();
    explicit cursor_event(ui::point, double const timestamp);

    bool operator==(cursor_event const &) const;
    bool operator!=(cursor_event const &) const;

    ui::point const &position() const;
    double timestamp() const;
    bool contains_in_window() const;

   private:
    ui::point _position;
    double _timestamp;
};

struct touch_event {
    touch_event();
    explicit touch_event(uintptr_t const identifier, ui::point position, double const timestamp);

    bool operator==(touch_event const &) const;
    bool operator!=(touch_event const &) const;

    uintptr_t identifier() const;
    ui::point const &position() const;
    double timestamp() const;

   private:
    uintptr_t _identifier;
    ui::point _position;
    double _timestamp;
};

struct key_event {
    key_event();
    explicit key_event(uint16_t const key_code, std::string characters, std::string raw_characters,
                       double const timestamp);

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

struct modifier_event {
    modifier_event();
    explicit modifier_event(modifier_flags const, double const timestamp);

    bool operator==(modifier_event const &) const;
    bool operator!=(modifier_event const &) const;

    modifier_flags flag() const;
    double timestamp() const;

   private:
    modifier_flags _flag;
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

static cursor constexpr cursor_tag{};
static touch constexpr touch_tag{};
static key constexpr key_tag{};
static modifier constexpr modifier_tag{};
}  // namespace yas::ui

namespace yas {
std::string to_string(ui::cursor_event const &);
std::string to_string(ui::touch_event const &);
std::string to_string(ui::key_event const &);
std::string to_string(ui::modifier_event const &);
std::string to_string(ui::event_phase const &);
std::string to_string(ui::modifier_flags const &);
std::string to_string(ui::event_type const &type);
}  // namespace yas

std::ostream &operator<<(std::ostream &, yas::ui::event_phase const &);
std::ostream &operator<<(std::ostream &, yas::ui::modifier_flags const &);
std::ostream &operator<<(std::ostream &, yas::ui::event_type const &event_type);
