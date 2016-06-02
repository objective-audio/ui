//
//  yas_ui_event.h
//

#pragma once

#include "yas_base.h"
#include "yas_ui_event_protocol.h"

namespace yas {
template <typename T, typename K>
class subject;

namespace ui {
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

        event_manager();
        event_manager(std::nullptr_t);

        subject<event, event_method> &subject();

        ui::event_inputtable &inputtable();

       private:
        ui::event_inputtable _inputtable = nullptr;
    };
}
}

template <>
struct std::hash<yas::ui::event> {
    std::size_t operator()(yas::ui::event const &key) const {
        return std::hash<uintptr_t>()(key.identifier());
    }
};
