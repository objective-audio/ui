//
//  yas_ui_metal_view.h
//

#pragma once

#include <MetalKit/MetalKit.h>
#include <objc_utils/yas_objc_macros.h>
#include <ui/yas_ui_types.h>

#if TARGET_OS_IPHONE
#elif TARGET_OS_MAC
#include <Foundation/NSGeometry.h>
#endif

@protocol YASUIMetalViewDelegate;

@interface YASUIMetalView : MTKView

@property (nonatomic, yas_weak_for_property) id<YASUIMetalViewDelegate> uiDelegate;

- (yas_edge_insets)uiSafeAreaInsets;
- (yas::ui::appearance)uiAppearance;

@end

@protocol YASUIMetalViewDelegate <NSObject>

- (void)uiMetalView:(YASUIMetalView *)view safeAreaInsetsDidChange:(yas_edge_insets)insets;

@end
