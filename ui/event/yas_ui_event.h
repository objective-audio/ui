//
//  yas_ui_event.h
//

#pragma once

#include <observing/yas_observing_umbrella.h>
#include <ui/yas_ui_event_protocol.h>
#include <ui/yas_ui_ptr.h>

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

    [[nodiscard]] static event_ptr make_shared(cursor const &);
    [[nodiscard]] static event_ptr make_shared(touch const &);
    [[nodiscard]] static event_ptr make_shared(key const &);
    [[nodiscard]] static event_ptr make_shared(modifier const &);

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

struct event_manager : event_inputtable {
    virtual ~event_manager() final;

    [[nodiscard]] observing::endable observe(observing::caller<event_ptr>::handler_f &&);

    [[nodiscard]] static event_manager_ptr make_shared();

   private:
    event_ptr _cursor_event{nullptr};
    std::unordered_map<uintptr_t, event_ptr> _touch_events;
    std::unordered_map<uint16_t, event_ptr> _key_events;
    std::unordered_map<uint32_t, event_ptr> _modifier_events;

    observing::notifier_ptr<event_ptr> const _notifier = observing::notifier<event_ptr>::make_shared();

    event_manager();

    event_manager(event_manager const &) = delete;
    event_manager(event_manager &&) = delete;
    event_manager &operator=(event_manager const &) = delete;
    event_manager &operator=(event_manager &&) = delete;

    void input_cursor_event(cursor_event const &value) override;
    void input_touch_event(event_phase const, touch_event const &) override;
    void input_key_event(event_phase const, key_event const &) override;
    void input_modifier_event(modifier_flags const &, double const) override;
};
}  // namespace yas::ui

namespace yas {
std::string to_string(ui::event const &);
}  // namespace yas

std::ostream &operator<<(std::ostream &, yas::ui::event const &);
