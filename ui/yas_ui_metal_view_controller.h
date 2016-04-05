//
//  yas_ui_metal_view_controller.h
//

#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>
#import "yas_objc_macros.h"
#import "yas_ui_renderer_protocol.h"
#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#elif TARGET_OS_MAC
#import <AppKit/AppKit.h>
#endif

NS_ASSUME_NONNULL_BEGIN

@class YASUIMetalView;

@interface YASUIMetalViewController : yas_objc_view_controller

@property (nonatomic, strong, readonly) MTKView *metalView;
@property (nonatomic, assign, getter=isPaused) BOOL paused;

- (void)initCommon NS_REQUIRES_SUPER;

- (void)setRenderer:(yas::ui::view_renderable)renderer;
- (yas::ui::view_renderable const &)renderer;

@end

NS_ASSUME_NONNULL_END
