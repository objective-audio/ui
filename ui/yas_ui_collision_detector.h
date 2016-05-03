//
//  yas_ui_collision_detector.h
//

#pragma once

#include <simd/simd.h>
#include "yas_base.h"
#include "yas_protocol.h"
#include "yas_ui_types.h"

namespace yas {
namespace ui {
    class collider;

    struct updatable_collision_detector : protocol {
        struct impl : protocol::impl {
            virtual void clear_colliders() = 0;
            virtual void push_front_collider(ui::collider &&) = 0;
        };

        explicit updatable_collision_detector(std::shared_ptr<impl>);

        void clear_colliders();
        void push_front_collider(ui::collider);
    };

    class collision_detector : public base {
       public:
        collision_detector();
        collision_detector(std::nullptr_t);

        ui::collider detect(ui::point const &);
        bool detect(ui::point const &, ui::collider const &);

        updatable_collision_detector updatable();

       private:
        class impl;
    };
}
}
