//
//  yas_ui_event.h
//

#pragma once

#include <ui/yas_ui_event_types.h>

namespace yas::ui {
class event_impl_base;

struct event final {
    template <typename T>
    class impl;

    event_phase phase() const;

    event_type type() const;
    std::type_info const &type_info() const;

    template <typename T>
    void set(typename T::type);

    template <typename T>
    typename T::type const &get() const;

    uintptr_t identifier() const;

    void set_phase(event_phase const &);

    bool operator==(event const &) const;
    bool operator!=(event const &) const;

    [[nodiscard]] static std::shared_ptr<event> make_shared(cursor const &);
    [[nodiscard]] static std::shared_ptr<event> make_shared(touch const &);
    [[nodiscard]] static std::shared_ptr<event> make_shared(key const &);
    [[nodiscard]] static std::shared_ptr<event> make_shared(modifier const &);

   private:
    std::shared_ptr<impl<cursor>> _cursor_impl = nullptr;
    std::shared_ptr<impl<touch>> _touch_impl = nullptr;
    std::shared_ptr<impl<key>> _key_impl = nullptr;
    std::shared_ptr<impl<modifier>> _modifier_impl = nullptr;

    explicit event(cursor const &);
    explicit event(touch const &);
    explicit event(key const &);
    explicit event(modifier const &);

    event(event const &) = delete;
    event(event &&) = delete;
    event &operator=(event const &) = delete;
    event &operator=(event &&) = delete;

    std::shared_ptr<event_impl_base> _impl() const;
};
}  // namespace yas::ui

namespace yas {
std::string to_string(ui::event const &);
}  // namespace yas

std::ostream &operator<<(std::ostream &, yas::ui::event const &);
