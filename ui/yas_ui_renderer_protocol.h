//
//  yas_ui_renderer_protocol.h
//

#pragma once

#include <CoreGraphics/CoreGraphics.h>
#include <MetalKit/MetalKit.h>
#include "yas_objc_macros.h"
#include "yas_protocol.h"

@class YASUIMetalView;

namespace yas {
namespace ui {
    class touch;

    enum class renderer_method {
        will_render,
        view_size_changed,
        scale_factor_changed,
    };

    struct view_renderable : protocol {
        struct impl : protocol::impl {
            virtual void view_configure(yas_objc_view *const view) = 0;
            virtual void view_size_will_change(yas_objc_view *const view, CGSize const size) = 0;
            virtual void view_render(yas_objc_view *const view) = 0;
        };

        explicit view_renderable(std::shared_ptr<impl> impl);
        view_renderable(std::nullptr_t);

        void configure(yas_objc_view *const view);
        void size_will_change(yas_objc_view *const view, CGSize const size);
        void render(yas_objc_view *const view);
    };
}
}