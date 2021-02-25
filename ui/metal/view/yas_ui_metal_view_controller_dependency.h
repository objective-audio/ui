//
//  yas_ui_metal_view_controller_dependency.h
//

#pragma once

#include <ui/yas_ui_objc.h>
#include <ui/yas_ui_ptr.h>
#include <ui/yas_ui_types.h>

namespace yas::ui {
struct view_renderable {
    virtual ~view_renderable() = default;

    virtual void view_configure(yas_objc_view *const view) = 0;
    virtual void view_size_will_change(yas_objc_view *const view, CGSize const size) = 0;
    virtual void view_safe_area_insets_did_change(yas_objc_view *const view, yas_edge_insets const insets) = 0;
    virtual void view_render(yas_objc_view *const view) = 0;
    virtual void view_appearance_did_change(yas_objc_view *const view, ui::appearance const) = 0;

    static view_renderable_ptr cast(view_renderable_ptr const &renderable) {
        return renderable;
    }
};
}  // namespace yas::ui
