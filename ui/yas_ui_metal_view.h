//
//  yas_ui_metal_view.h
//

#pragma once

#include <MetalKit/MetalKit.h>

namespace yas {
namespace ui {
    class event_manager;
}
}

@interface YASUIMetalView : MTKView

- (yas::ui::event_manager const &)event_manager;

@end
