//
//  yas_ui_collision_detector_protocol.h
//

#pragma once

#include "yas_protocol.h"

namespace yas {
namespace ui {
    class collider;

    enum class collider_update_reason : std::size_t {
        existence,
        geometry,

        count,
    };

    using collider_update_reason_t = std::underlying_type<ui::collider_update_reason>::type;
    static std::size_t const collider_update_reason_count =
        static_cast<collider_update_reason_t>(ui::collider_update_reason::count);

    struct updatable_collision_detector : protocol {
        struct impl : protocol::impl {
            virtual void set_needs_update(ui::collider_update_reason const) = 0;
            virtual void clear_colliders_if_needed() = 0;
            virtual void push_front_collider_if_needed(ui::collider &&) = 0;
            virtual void finalize() = 0;
        };

        explicit updatable_collision_detector(std::shared_ptr<impl>);
        updatable_collision_detector(std::nullptr_t);

        void set_needs_update(ui::collider_update_reason const);
        void clear_colliders_if_needed();
        void push_front_collider_if_needed(ui::collider);
        void finalize();
    };
}
}