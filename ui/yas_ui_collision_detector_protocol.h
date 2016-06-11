//
//  yas_ui_collision_detector_protocol.h
//

#pragma once

#include "yas_flagset.h"
#include "yas_protocol.h"

namespace yas {
namespace ui {
    class collider;

    struct updatable_collision_detector : protocol {
        struct impl : protocol::impl {
            virtual bool is_updating() = 0;
            virtual void begin_update() = 0;
            virtual void push_front_collider(ui::collider &&) = 0;
            virtual void end_update() = 0;
        };

        explicit updatable_collision_detector(std::shared_ptr<impl>);
        updatable_collision_detector(std::nullptr_t);

        bool is_updating();
        void begin_update();
        void push_front_collider(ui::collider);
        void end_update();
    };
}
}