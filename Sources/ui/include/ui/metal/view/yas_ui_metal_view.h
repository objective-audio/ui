#pragma once

#include <ui/metal/view/yas_ui_metal_view_dependency.h>
#include <ui/metal/view/yas_ui_metal_view_objc.h>

@protocol YASUIMetalViewDelegate;

@interface YASUIMetalView (objc)

@property (nonatomic, yas_weak_for_property) id<YASUIMetalViewDelegate> uiDelegate;

- (yas::ui::region_insets)uiSafeAreaInsets;
- (yas::ui::appearance)uiAppearance;

- (void)configure;
- (void)set_event_manager:(std::shared_ptr<yas::ui::event_manager_for_view> const &)manager;

- (yas::ui::point)view_location_from_ui_position:(yas::ui::point)position;
- (yas::ui::point)ui_position_from_view_location:(yas::ui::point)location;

@end

@protocol YASUIMetalViewDelegate <NSObject>

- (void)uiMetalView:(YASUIMetalView *)view safeAreaInsetsDidChange:(yas::ui::region_insets)insets;

@end
