//
//  yas_ui_renderer_protocol.h
//

#pragma once

#include <CoreGraphics/CoreGraphics.h>
#include <MetalKit/MetalKit.h>
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
            virtual void view_configure(YASUIMetalView *const view) = 0;
            virtual void view_size_will_change(YASUIMetalView *const view, CGSize const size) = 0;
            virtual void view_render(YASUIMetalView *const view) = 0;
        };

        explicit view_renderable(std::shared_ptr<impl> impl);

        void configure(YASUIMetalView *const view);
        void size_will_change(YASUIMetalView *const view, CGSize const size);
        void render(YASUIMetalView *const view);
    };
}
}