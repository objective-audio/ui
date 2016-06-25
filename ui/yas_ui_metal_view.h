//
//  yas_ui_metal_view.h
//

#pragma once

#include <MetalKit/MetalKit.h>

@interface YASUIMetalView : MTKView

#if TARGET_OS_IPHONE
- (CGSize)drawableSize;
#endif

@end
