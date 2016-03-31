//
//  yas_ui_metal_view.h
//

#import <Metal/Metal.h>
#import <QuartzCore/CAMetalLayer.h>
#import "yas_objc_macros.h"
#import "yas_ui_renderer_protocol.h"
#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#elif TARGET_OS_MAC
#import <AppKit/AppKit.h>
#endif

NS_ASSUME_NONNULL_BEGIN

@interface YASUIMetalView : yas_objc_view

@property (nonatomic, strong, readonly) id<MTLDevice> device;
@property (nonatomic, strong, readonly) id<CAMetalDrawable> currentDrawable;
@property (nonatomic, strong, readonly, nullable) MTLRenderPassDescriptor *renderPassDescriptor;
@property (nonatomic, assign) NSUInteger sampleCount;
@property (nonatomic, assign, getter=isPaused) BOOL paused;
@property (nonatomic, assign) CGFloat contentsScale;

- (void)setRenderer:(yas::ui::view_renderable)renderer;
- (yas::ui::view_renderable)renderer;

- (void)draw;

@end

NS_ASSUME_NONNULL_END
