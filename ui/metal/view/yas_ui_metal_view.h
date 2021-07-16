//
//  yas_ui_metal_view.h
//

#pragma once

#include <MetalKit/MetalKit.h>
#include <ui/yas_ui_objc.h>
#include <ui/yas_ui_types.h>

@protocol YASUIMetalViewDelegate;

@interface YASUIMetalView : MTKView

@property (nonatomic, yas_weak_for_property) id<YASUIMetalViewDelegate> uiDelegate;

- (yas::ui::region_insets)uiSafeAreaInsets;
- (yas::ui::appearance)uiAppearance;

- (void)set_event_manager:(std::shared_ptr<yas::ui::metal_view_event_manager_interface> const &)manager;

@end

@protocol YASUIMetalViewDelegate <NSObject>

- (void)uiMetalView:(YASUIMetalView *)view safeAreaInsetsDidChange:(yas::ui::region_insets)insets;

@end
