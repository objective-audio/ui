//
//  yas_ui_event_protocol.h
//

#pragma once

#include <simd/simd.h>
#include <string>
#include "yas_protocol.h"
#include "yas_ui_types.h"

namespace yas {
namespace ui {
    enum class event_method { cursor_changed, touch_changed, key_changed, modifier_changed };

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
        explicit cursor_event(ui::point);

        bool operator==(cursor_event const &) const;
        bool operator!=(cursor_event const &) const;

        ui::point const &position() const;
        bool contains_in_window() const;

       private:
        ui::point _position;
    };

    struct touch_event {
        touch_event();
        explicit touch_event(uintptr_t const identifier, ui::point position);

        bool operator==(touch_event const &) const;
        bool operator!=(touch_event const &) const;

        uintptr_t identifier() const;
        ui::point const &position() const;

       private:
        uintptr_t _identifier;
        ui::point _position;
    };

    struct key_event {
        key_event();
        explicit key_event(uint16_t const key_code, std::string characters, std::string raw_characters);

        bool operator==(key_event const &) const;
        bool operator!=(key_event const &) const;

        uint16_t key_code() const;
        std::string const &characters() const;
        std::string const &raw_characters() const;

       private:
        uint16_t _key_code;
        std::string _characters;
        std::string _raw_characters;
    };

    struct modifier_event {
        modifier_event();
        explicit modifier_event(modifier_flags const);

        bool operator==(modifier_event const &) const;
        bool operator!=(modifier_event const &) const;

        modifier_flags flag() const;

       private:
        modifier_flags _flag;
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

    struct event_inputtable : protocol {
        struct impl : protocol::impl {
            virtual void input_cursor_event(cursor_event &&value) = 0;
            virtual void input_touch_event(event_phase const, touch_event &&) = 0;
            virtual void input_key_event(event_phase const, key_event &&) = 0;
            virtual void input_modifier_event(modifier_flags &&) = 0;
        };

        explicit event_inputtable(std::shared_ptr<impl>);

        void input_cursor_event(cursor_event);
        void input_touch_event(event_phase const, touch_event);
        void input_key_event(event_phase const, key_event);
        void input_modifier_event(modifier_flags);
    };
}

std::string to_string(ui::event_phase const &);
std::string to_string(ui::modifier_flags const &);
}

std::ostream &operator<<(std::ostream &, yas::ui::event_phase const &);
std::ostream &operator<<(std::ostream &, yas::ui::modifier_flags const &);
