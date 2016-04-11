//
//  yas_ui_event.h
//

#pragma once

#include "yas_base.h"
#include "yas_observing.h"
#include "yas_ui_event_protocol.h"

namespace yas {
namespace ui {
    struct manageable_event : protocol {
        struct impl : protocol::impl {
            virtual void set_phase(event_phase &&) = 0;
        };

        explicit manageable_event(std::shared_ptr<impl>);

        template <typename T>
        void set(typename T::type);

        void set_phase(event_phase);
    };

    class event : public base {
        using super_class = base;

       public:
        explicit event(cursor const &);
        explicit event(touch const &);
        explicit event(key const &);
        explicit event(modifier const &);
        event(std::nullptr_t);

        event_phase phase() const;

        std::type_info const &type_info() const;

        template <typename T>
        typename T::type const &get() const;

        manageable_event manageable();

        class impl_base;

        template <typename T>
        class impl;
    };

    class event_manager : public base {
        using super_class = base;

       public:
        event_manager();
        event_manager(std::nullptr_t);

        subject<event> &subject();

        event_inputtable inputtable();

        class impl;
    };
}
}

template <>
struct std::hash<yas::ui::event> {
    std::size_t operator()(yas::ui::event const &key) const {
        return std::hash<uintptr_t>()(key.identifier());
    }
};
