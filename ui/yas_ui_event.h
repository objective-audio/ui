//
//  yas_ui_event.h
//

#pragma once

#include <chaining/yas_chaining_umbrella.h>
#include "yas_ui_event_protocol.h"
#include "yas_ui_ptr.h"

namespace yas::ui {
class event_impl_base;

struct manageable_event {
    virtual ~manageable_event() = default;

    template <typename T>
    void set(typename T::type);

    virtual void set_phase(event_phase const &) = 0;
    virtual std::shared_ptr<event_impl_base> get_impl() = 0;
};

using manageable_event_ptr = std::shared_ptr<manageable_event>;

struct event : manageable_event, std::enable_shared_from_this<event> {
    template <typename T>
    class impl;

    virtual ~event() final;

    event_phase phase() const;

    std::type_info const &type_info() const;

    template <typename T>
    typename T::type const &get() const;

    uintptr_t identifier() const;

    ui::manageable_event_ptr manageable();

    bool operator==(event const &) const;
    bool operator!=(event const &) const;

    [[nodiscard]] static event_ptr make_shared(cursor const &);
    [[nodiscard]] static event_ptr make_shared(touch const &);
    [[nodiscard]] static event_ptr make_shared(key const &);
    [[nodiscard]] static event_ptr make_shared(modifier const &);

   private:
    std::shared_ptr<event_impl_base> _impl;

    explicit event(cursor const &);
    explicit event(touch const &);
    explicit event(key const &);
    explicit event(modifier const &);

    void set_phase(event_phase const &) override;
    std::shared_ptr<event_impl_base> get_impl() override;
};

struct event_manager : event_inputtable, std::enable_shared_from_this<event_manager> {
    enum class method { cursor_changed, touch_changed, key_changed, modifier_changed };

    struct context {
        method const &method;
        event_ptr const &event;
    };

    virtual ~event_manager() final;

    [[nodiscard]] chaining::chain_relayed_unsync_t<event_ptr, context> chain(method const &) const;
    [[nodiscard]] chaining::chain_unsync_t<context> chain() const;

    ui::event_inputtable_ptr inputtable();

    [[nodiscard]] static event_manager_ptr make_shared();

   private:
    class impl;

    std::unique_ptr<impl> _impl;

    event_manager();

    void input_cursor_event(cursor_event const &value) override;
    void input_touch_event(event_phase const, touch_event const &) override;
    void input_key_event(event_phase const, key_event const &) override;
    void input_modifier_event(modifier_flags const &, double const) override;
};
}  // namespace yas::ui

namespace yas {
std::string to_string(ui::event const &);
std::string to_string(ui::event_manager::method const &);
}  // namespace yas

std::ostream &operator<<(std::ostream &, yas::ui::event const &);
std::ostream &operator<<(std::ostream &, yas::ui::event_manager::method const &);
