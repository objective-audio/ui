//
//  yas_ui_renderer_protocol.h
//

#pragma once

#include <CoreGraphics/CoreGraphics.h>
#include <MetalKit/MetalKit.h>
#include <objc_utils/yas_objc_macros.h>
#include "yas_ui_types.h"

namespace yas::ui {
struct view_renderable {
    virtual ~view_renderable() = default;

    virtual void view_configure(yas_objc_view *const view) = 0;
    virtual void view_size_will_change(yas_objc_view *const view, CGSize const size) = 0;
    virtual void view_safe_area_insets_did_change(yas_objc_view *const view, yas_edge_insets const insets) = 0;
    virtual void view_render(yas_objc_view *const view) = 0;
    virtual void view_appearance_did_change(yas_objc_view *const view, ui::appearance const) = 0;
};

using view_renderable_ptr = std::shared_ptr<view_renderable>;
}  // namespace yas::ui
