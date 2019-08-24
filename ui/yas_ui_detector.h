//
//  yas_ui_detector.h
//

#pragma once

#include "yas_ui_collider.h"
#include "yas_ui_detector_protocol.h"
#include "yas_ui_ptr.h"
#include "yas_ui_types.h"

namespace yas::ui {

struct detector final {
    virtual ~detector();

    ui::collider_ptr detect(ui::point const &) const;
    bool detect(ui::point const &, ui::collider_ptr const &) const;

    ui::updatable_detector &updatable();

    [[nodiscard]] static detector_ptr make_shared();

   private:
    class impl;

    std::shared_ptr<impl> _impl;

    ui::updatable_detector _updatable = nullptr;

    detector();
};
}  // namespace yas::ui
