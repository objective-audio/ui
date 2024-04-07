//
//  yas_ui_metal_view_controller.h
//

#pragma once

#include <cpp-utils/yas_objc_ptr.h>
#include <ui/metal/view/yas_ui_metal_view.h>
#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#elif TARGET_OS_MAC
#import <AppKit/AppKit.h>
#endif

NS_ASSUME_NONNULL_BEGIN

@class YASUIMetalView;

@interface YASUIMetalViewController : yas_objc_view_controller

@property (nonatomic, strong, readonly) YASUIMetalView *metalView;
@property (nonatomic, assign, getter=isPaused) BOOL paused;

- (void)initCommon NS_REQUIRES_SUPER;

- (std::shared_ptr<yas::ui::view_look> const &)view_look;

- (void)configure_with_metal_system:(std::shared_ptr<yas::ui::metal_system_for_view> const &)metal_system
                           renderer:(std::shared_ptr<yas::ui::renderer_for_view> const &)renderer
                      event_manager:(std::shared_ptr<yas::ui::event_manager_for_view> const &)event_manager;

- (std::shared_ptr<yas::ui::renderer_for_view> const &)renderer;

@end

NS_ASSUME_NONNULL_END
