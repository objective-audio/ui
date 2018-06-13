//
//  yas_ui_event.h
//

#pragma once

#include "yas_base.h"
#include "yas_flow.h"
#include "yas_ui_event_protocol.h"

namespace yas {
template <typename K, typename T>
class subject;
}

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

class event : public base {
   public:
    class impl_base;

    template <typename T>
    class impl;

    explicit event(cursor const &);
    explicit event(touch const &);
    explicit event(key const &);
    explicit event(modifier const &);
    event(std::nullptr_t);

    virtual ~event() final;

    event_phase phase() const;

    std::type_info const &type_info() const;

    template <typename T>
    typename T::type const &get() const;

    ui::manageable_event &manageable();

   private:
    ui::manageable_event _manageable = nullptr;
};

class event_manager : public base {
   public:
    class impl;

    enum class method { cursor_changed, touch_changed, key_changed, modifier_changed };

    struct context {
        method const &method;
        event const &event;
    };

    event_manager();
    event_manager(std::nullptr_t);

    virtual ~event_manager() final;

    subject<method, event> &subject();
    [[nodiscard]] flow::node<event, context, context, false> begin_flow(method const &) const;
    [[nodiscard]] flow::node<context, context, context, false> begin_flow() const;

    ui::event_inputtable &inputtable();

   private:
    ui::event_inputtable _inputtable = nullptr;
};
}  // namespace yas::ui

namespace yas {
std::string to_string(ui::event const &);
std::string to_string(ui::event_manager::method const &);
}  // namespace yas

std::ostream &operator<<(std::ostream &, yas::ui::event const &);
std::ostream &operator<<(std::ostream &, yas::ui::event_manager::method const &);

template <>
struct std::hash<yas::ui::event> {
    std::size_t operator()(yas::ui::event const &key) const {
        return std::hash<uintptr_t>()(key.identifier());
    }
};
