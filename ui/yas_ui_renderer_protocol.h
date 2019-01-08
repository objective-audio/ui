//
//  yas_ui_renderer_protocol.h
//

#pragma once

#include <CoreGraphics/CoreGraphics.h>
#include <MetalKit/MetalKit.h>
#include <cpp_utils/yas_protocol.h>
#include <objc_utils/yas_objc_macros.h>

@class YASUIMetalView;

namespace yas::ui {
class touch;

struct view_renderable : protocol {
    struct impl : protocol::impl {
        virtual void view_configure(yas_objc_view *const view) = 0;
        virtual void view_size_will_change(yas_objc_view *const view, CGSize const size) = 0;
        virtual void view_safe_area_insets_did_change(yas_objc_view *const view) = 0;
        virtual void view_render(yas_objc_view *const view) = 0;
    };

    explicit view_renderable(std::shared_ptr<impl> impl);
    view_renderable(std::nullptr_t);

    void configure(yas_objc_view *const view);
    void size_will_change(yas_objc_view *const view, CGSize const size);
    void safe_area_insets_did_change(yas_objc_view *const view, yas_edge_insets const insets);
    void render(yas_objc_view *const view);
};
}  // namespace yas::ui
