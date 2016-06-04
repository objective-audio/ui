//
//  yas_ui_collision_detector.h
//

#pragma once

#include "yas_base.h"
#include "yas_ui_collision_detector_protocol.h"
#include "yas_ui_types.h"

namespace yas {
namespace ui {
    class collider;

    class collision_detector : public base {
       public:
        collision_detector();
        collision_detector(std::nullptr_t);

        ui::collider detect(ui::point const &) const;
        bool detect(ui::point const &, ui::collider const &) const;

        ui::updatable_collision_detector &updatable();

       private:
        class impl;

        ui::updatable_collision_detector _updatable = nullptr;
    };
}
}
