//
//  yas_ui_metal_view_controller_dependency.h
//

#pragma once

#include <ui/yas_ui_objc.h>
#include <ui/yas_ui_types.h>

namespace yas::ui {
struct view_renderer_interface {
    virtual ~view_renderer_interface() = default;

    virtual void view_configure(yas_objc_view *const view) = 0;
    virtual void view_render(yas_objc_view *const view) = 0;
};
}  // namespace yas::ui
