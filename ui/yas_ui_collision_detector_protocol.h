//
//  yas_ui_collision_detector_protocol.h
//

#pragma once

#include "yas_protocol.h"

namespace yas {
namespace ui {
    class collider;

    struct updatable_collision_detector : protocol {
        struct impl : protocol::impl {
            virtual void set_needs_update_colliders() = 0;
            virtual void clear_colliders_if_needed() = 0;
            virtual void push_front_collider_if_needed(ui::collider &&) = 0;
            virtual void finalize() = 0;
        };

        explicit updatable_collision_detector(std::shared_ptr<impl>);
        updatable_collision_detector(std::nullptr_t);

        void set_needs_update_colliders();
        void clear_colliders_if_needed();
        void push_front_collider_if_needed(ui::collider);
        void finalize();
    };
}
}