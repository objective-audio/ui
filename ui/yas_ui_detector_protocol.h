//
//  yas_ui_detector_protocol.h
//

#pragma once

#include "yas_ui_ptr.h"

namespace yas::ui {
struct updatable_detector {
    virtual ~updatable_detector() = default;

    virtual bool is_updating() = 0;
    virtual void begin_update() = 0;
    virtual void push_front_collider(ui::collider_ptr const &) = 0;
    virtual void end_update() = 0;
};

using updatable_detector_ptr = std::shared_ptr<updatable_detector>;
}  // namespace yas::ui
