//
//  yas_ui_detector.h
//

#pragma once

#include "yas_base.h"
#include "yas_ui_detector_protocol.h"
#include "yas_ui_types.h"

namespace yas::ui {
class collider;

class detector : public base {
   public:
    detector();
    detector(std::nullptr_t);

    virtual ~detector() final;

    ui::collider detect(ui::point const &) const;
    bool detect(ui::point const &, ui::collider const &) const;

    ui::updatable_detector &updatable();

   private:
    class impl;

    ui::updatable_detector _updatable = nullptr;
};
}  // namespace yas::ui
