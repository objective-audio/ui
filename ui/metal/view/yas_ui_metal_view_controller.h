//
//  yas_ui_metal_view_controller.h
//

#pragma once

#include <cpp_utils/yas_objc_ptr.h>
#include <ui/yas_ui_metal_view.h>
#include <ui/yas_ui_metal_view_controller_dependency.h>
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

- (std::shared_ptr<yas::ui::view_look> const &)view_look;

- (void)configure_with_metal_system:(std::shared_ptr<yas::ui::view_metal_system_interface> const &)metal_system
                           renderer:(std::shared_ptr<yas::ui::view_renderer_interface> const &)renderer;

- (std::shared_ptr<yas::ui::view_renderer_interface> const &)renderer;

- (void)set_event_manager:(std::shared_ptr<yas::ui::metal_view_event_manager_interface> const &)event_manager;
- (std::shared_ptr<yas::ui::metal_view_event_manager_interface> const &)event_manager;

@end

NS_ASSUME_NONNULL_END
