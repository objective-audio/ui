//
//  yas_ui_metal_view_controller.h
//

#pragma once

#include <cpp_utils/yas_objc_ptr.h>
#include "yas_ui_metal_view.h"
#include "yas_ui_renderer_protocol.h"
#if TARGET_OS_IPHONE
#include <UIKit/UIKit.h>
#elif TARGET_OS_MAC
#include <AppKit/AppKit.h>
#endif

NS_ASSUME_NONNULL_BEGIN

@class YASUIMetalView;

@interface YASUIMetalViewController : yas_objc_view_controller

@property (nonatomic, strong, readonly) YASUIMetalView *metalView;
@property (nonatomic, assign, getter=isPaused) BOOL paused;

- (void)initCommon NS_REQUIRES_SUPER;

- (void)setRenderable:(yas::ui::view_renderable_ptr const &)renderer;
- (yas::ui::view_renderable_ptr const &)renderable;

@end

NS_ASSUME_NONNULL_END
