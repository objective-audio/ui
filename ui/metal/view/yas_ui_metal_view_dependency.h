//
//  yas_ui_metal_view_dependency.h
//

#pragma once

#include <ui/yas_ui_event_protocol.h>

namespace yas::ui {
struct metal_view_event_manager_interface {
    virtual ~metal_view_event_manager_interface() = default;

    virtual void input_cursor_event(cursor_event const &) = 0;
    virtual void input_touch_event(event_phase const, touch_event const &) = 0;
    virtual void input_key_event(event_phase const, key_event const &) = 0;
    virtual void input_modifier_event(modifier_flags const &, double const timestamp) = 0;

    static std::shared_ptr<metal_view_event_manager_interface> cast(
        std::shared_ptr<metal_view_event_manager_interface> const &inputtable) {
        return inputtable;
    }
};
}  // namespace yas::ui
