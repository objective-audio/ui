//
//  yas_ui_event.h
//

#pragma once

#include <chaining/yas_chaining_umbrella.h>
#include "yas_ui_event_protocol.h"
#include "yas_ui_ptr.h"

namespace yas::ui {
struct manageable_event : protocol {
    struct impl : protocol::impl {
        virtual void set_phase(event_phase &&) = 0;
    };

    explicit manageable_event(std::shared_ptr<impl>);
    manageable_event(std::nullptr_t);

    template <typename T>
    void set(typename T::type);

    void set_phase(event_phase);
};

struct event {
    class impl_base;

    template <typename T>
    class impl;

    virtual ~event() final;

    event_phase phase() const;

    std::type_info const &type_info() const;

    template <typename T>
    typename T::type const &get() const;

    uintptr_t identifier() const;

    ui::manageable_event &manageable();

    bool operator==(event const &) const;
    bool operator!=(event const &) const;

    [[nodiscard]] static event_ptr make_shared(cursor const &);
    [[nodiscard]] static event_ptr make_shared(touch const &);
    [[nodiscard]] static event_ptr make_shared(key const &);
    [[nodiscard]] static event_ptr make_shared(modifier const &);

   private:
    std::shared_ptr<impl_base> _impl;

    ui::manageable_event _manageable = nullptr;

    explicit event(cursor const &);
    explicit event(touch const &);
    explicit event(key const &);
    explicit event(modifier const &);
};

struct event_manager {
    class impl;

    enum class method { cursor_changed, touch_changed, key_changed, modifier_changed };

    struct context {
        method const &method;
        event_ptr const &event;
    };

    virtual ~event_manager() final;

    [[nodiscard]] chaining::chain_relayed_unsync_t<event_ptr, context> chain(method const &) const;
    [[nodiscard]] chaining::chain_unsync_t<context> chain() const;

    ui::event_inputtable &inputtable();

    [[nodiscard]] static event_manager_ptr make_shared();

   private:
    std::shared_ptr<impl> _impl;

    ui::event_inputtable _inputtable = nullptr;

    event_manager();
};
}  // namespace yas::ui

namespace yas {
std::string to_string(ui::event const &);
std::string to_string(ui::event_manager::method const &);
}  // namespace yas

std::ostream &operator<<(std::ostream &, yas::ui::event const &);
std::ostream &operator<<(std::ostream &, yas::ui::event_manager::method const &);
