//
//  yas_ui_metal_view.h
//

#import <Metal/Metal.h>
#import <QuartzCore/CAMetalLayer.h>
#import "yas_objc_macros.h"
#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#elif TARGET_OS_MAC
#import <AppKit/AppKit.h>
#endif

NS_ASSUME_NONNULL_BEGIN

@protocol YASMetalViewDelegate;

@interface YASMetalView : yas_objc_view

@property (nonatomic, yas_weak_for_property) id<YASMetalViewDelegate> delegate;
@property (nonatomic, strong, readonly) id<MTLDevice> device;
@property (nonatomic, strong, readonly) id<CAMetalDrawable> currentDrawable;
@property (nonatomic, strong, readonly, nullable) MTLRenderPassDescriptor *renderPassDescriptor;
@property (nonatomic, assign) NSUInteger sampleCount;
@property (nonatomic, assign, getter=isPaused) BOOL paused;
@property (nonatomic, assign) CGFloat contentsScale;

- (void)draw;

@end

@protocol YASMetalViewDelegate <NSObject>

@optional

- (void)metalView:(YASMetalView *)view drawableSizeWillChange:(CGSize)size;
- (void)drawInMetalView:(YASMetalView *)view;

@end

NS_ASSUME_NONNULL_END
