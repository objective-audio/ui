//
//  yas_ui_detector.h
//

#pragma once

#include <deque>
#include "yas_ui_collider.h"
#include "yas_ui_detector_protocol.h"
#include "yas_ui_ptr.h"
#include "yas_ui_types.h"

namespace yas::ui {
struct detector final : updatable_detector {
    virtual ~detector();

    std::optional<ui::collider_ptr> detect(ui::point const &) const;
    bool detect(ui::point const &, ui::collider_ptr const &) const;

    [[nodiscard]] static detector_ptr make_shared();

   private:
    std::deque<ui::collider_ptr> _colliders;
    bool _updating = true;

    detector();

    bool is_updating() override;
    void begin_update() override;
    void push_front_collider(ui::collider_ptr const &) override;
    void end_update() override;
};
}  // namespace yas::ui
