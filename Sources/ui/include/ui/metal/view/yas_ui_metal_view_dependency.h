//
//  yas_ui_metal_view_dependency.h
//

#pragma once

#include <ui/event/yas_ui_event_types.h>

namespace yas::ui {
struct event_manager_for_view {
    virtual ~event_manager_for_view() = default;

    virtual void input_cursor_event(cursor_phase const, cursor_event const &) = 0;
    virtual void input_touch_event(event_phase const, touch_event const &) = 0;
    virtual void input_key_event(event_phase const, key_event const &) = 0;
    virtual void input_modifier_event(modifier_flags const &, double const timestamp) = 0;
    virtual void input_pinch_event(event_phase const, pinch_event const &) = 0;
    virtual void input_scroll_event(event_phase const phase, scroll_event const &) = 0;
};
}  // namespace yas::ui
