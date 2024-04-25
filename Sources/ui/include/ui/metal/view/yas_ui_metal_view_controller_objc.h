//
//  yas_ui_metal_view_controller.h
//

#pragma once

#include <ui/common/yas_ui_objc.h>
#include <ui/metal/view/yas_ui_metal_view_objc.h>

NS_ASSUME_NONNULL_BEGIN

@class YASUIMetalView;

@interface YASUIMetalViewController : yas_objc_view_controller

@property (nonatomic, strong, readonly) YASUIMetalView *metalView;
@property (nonatomic, assign, getter=isPaused) BOOL paused;

- (void)initCommon NS_REQUIRES_SUPER;

@end

NS_ASSUME_NONNULL_END
