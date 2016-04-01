//
//  yas_ui_metal_view.m
//

#import <QuartzCore/QuartzCore.h>
#import "yas_objc_ptr.h"
#import "yas_ui_metal_view.h"
#import "yas_ui_renderer.h"

NS_ASSUME_NONNULL_BEGIN

using namespace yas;

namespace yas {
namespace ui {
    namespace metal_view {
        struct cpp_variables {
            ui::view_renderable renderer{nullptr};
        };
    }
}
}

@interface YASUIMetalView ()

@property (nonatomic, strong, nullable) MTLRenderPassDescriptor *renderPassDescriptor;
@property (nonatomic, strong, nullable) id<CAMetalDrawable> drawable;

#if TARGET_OS_IPHONE
@property (nonatomic, strong, nullable) CADisplayLink *displayLink;
#elif TARGET_OS_MAC
@property (nonatomic, strong, nullable) NSTimer *displayTimer;
#endif

@end

@implementation YASUIMetalView {
    BOOL _needsUpdateDrawableSize;
    BOOL _paused;

    ui::metal_view::cpp_variables _cpp;
}

+ (Class)layerClass {
    return [CAMetalLayer class];
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self initCommon];
    }
    return self;
}

- (nullable instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self initCommon];
    }
    return self;
}

- (void)initCommon {
#if (TARGET_OS_MAC && !TARGET_OS_IPHONE)
    [self setWantsLayer:YES];
#endif

    CAMetalLayer *metalLayer = self.metalLayer;

    metalLayer.opaque = YES;
    metalLayer.backgroundColor = NULL;
    metalLayer.presentsWithTransaction = NO;
    metalLayer.drawsAsynchronously = YES;
    metalLayer.framebufferOnly = YES;
    metalLayer.pixelFormat = MTLPixelFormatBGRA8Unorm;
    metalLayer.contentsScale = 1.0;

    auto device = make_objc_ptr(MTLCreateSystemDefaultDevice());
    metalLayer.device = device.object();

    _paused = NO;
    _sampleCount = 1;
    _needsUpdateDrawableSize = YES;

    yas_weak_for_block typeof(self) wself = self;

    [[NSNotificationCenter defaultCenter] addObserverForName:NSViewFrameDidChangeNotification
                                                      object:self
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification *_Nonnull note) {
                                                      [wself _setNeedsUpdateDrawableSize];
                                                  }];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    yas_super_dealloc();
}

- (CAMetalLayer *)metalLayer {
    return (CAMetalLayer *)self.layer;
}

- (id<MTLDevice>)device {
    return self.metalLayer.device;
}

- (BOOL)acceptsFirstResponder {
    return YES;
}

#if TARGET_OS_IPHONE

- (void)setContentScaleFactor:(CGFloat)contentScaleFactor {
    [super setContentScaleFactor:contentScaleFactor];

    _needsUpdateDrawableSize = YES;
}

- (void)layoutSubviews {
    [super layoutSubviews];

    _needsUpdateDrawableSize = YES;
}

- (void)didMoveToSuperview {
    [self _updateTimerPaused];
}

#elif TARGET_OS_MAC

- (CALayer *)makeBackingLayer {
    return [CAMetalLayer layer];
}

- (void)viewDidMoveToSuperview {
    [self _updateTimerPaused];
}

#endif

- (id<CAMetalDrawable>)currentDrawable {
    while (!_drawable) {
        self.drawable = [self.metalLayer nextDrawable];
        if (!_drawable) {
            NSLog(@"CurrentDrawable is nil");
        }
    }

    return _drawable;
}

- (void)setPaused:(BOOL)pause {
    if (_paused != pause) {
        _paused = pause;

        [self _updateTimerPaused];
    }
}

- (BOOL)isPaused {
    return _paused;
}

- (void)setContentsScale:(CGFloat)contentsScale {
    self.metalLayer.contentsScale = contentsScale;

    [self _setNeedsUpdateDrawableSize];
}

- (CGFloat)contentsScale {
    return self.metalLayer.contentsScale;
}

- (void)setRenderer:(yas::ui::view_renderable)renderer {
    _cpp.renderer = renderer;
    renderer.configure(self);
}

- (yas::ui::view_renderable)renderer {
    return _cpp.renderer;
}

- (void)draw {
    @autoreleasepool {
        CGSize drawableSize = self.bounds.size;

        if (drawableSize.width == 0 || drawableSize.height == 0) {
            return;
        }

        if (_needsUpdateDrawableSize) {
            CGFloat const scale = self.layer.contentsScale;

            drawableSize.width *= scale;
            drawableSize.height *= scale;

            if (_cpp.renderer) {
                _cpp.renderer.drawable_size_will_change(self, drawableSize);
            }

            self.metalLayer.drawableSize = drawableSize;

            _needsUpdateDrawableSize = NO;
        }

        [self _updateRenderPassDescriptor];

        if (_cpp.renderer) {
            _cpp.renderer.render(self);
        }

        self.drawable = nil;
    }
}

#pragma mark -

- (void)_updateRenderPassDescriptor {
    id<CAMetalDrawable> drawable = self.currentDrawable;
    assert(drawable);

    id<MTLTexture> drawableTexture = drawable.texture;

    if (_renderPassDescriptor == nil) {
        self.renderPassDescriptor = [MTLRenderPassDescriptor renderPassDescriptor];

        auto color_attachment = make_objc_ptr([MTLRenderPassColorAttachmentDescriptor new]);
        auto colorAttachment = color_attachment.object();
        colorAttachment.loadAction = MTLLoadActionClear;
        colorAttachment.clearColor = MTLClearColorMake(0.0f, 0.0f, 0.0f, 1.0f);

        [_renderPassDescriptor.colorAttachments setObject:colorAttachment atIndexedSubscript:0];
    }

    MTLRenderPassColorAttachmentDescriptor *colorAttachment =
        [_renderPassDescriptor.colorAttachments objectAtIndexedSubscript:0];
    id<MTLTexture> attachmentTexture = colorAttachment.texture;

    if (_sampleCount > 1) {
        @autoreleasepool {
            if (!attachmentTexture || (attachmentTexture.width != drawableTexture.width) ||
                (attachmentTexture.height != drawableTexture.height) ||
                (attachmentTexture.sampleCount != _sampleCount)) {
                MTLTextureDescriptor *desc =
                    [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatBGRA8Unorm
                                                                       width:drawableTexture.width
                                                                      height:drawableTexture.height
                                                                   mipmapped:NO];
                desc.textureType = MTLTextureType2DMultisample;
                desc.sampleCount = _sampleCount;
                desc.resourceOptions = MTLResourceCPUCacheModeDefaultCache | MTLResourceStorageModePrivate |
                                       MTLResourceOptionCPUCacheModeDefault;
                desc.usage = MTLTextureUsageRenderTarget;

                attachmentTexture = yas_autorelease([self.device newTextureWithDescriptor:desc]);
            }

            colorAttachment.texture = attachmentTexture;
        }

        colorAttachment.resolveTexture = drawableTexture;
        colorAttachment.storeAction = MTLStoreActionMultisampleResolve;
    } else {
        colorAttachment.texture = drawableTexture;
        colorAttachment.storeAction = MTLStoreActionStore;
    }
}

#if TARGET_OS_IPHONE

- (void)_addRenderTimer {
    if (!_displayLink) {
        self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(draw)];
        _displayLink.frameInterval = 1;
        [_displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    }
}

- (void)_removeRenderTimer {
    if (_displayLink) {
        [_displayLink invalidate];
        self.displayLink = nil;
        self.renderPassDescriptor = nil;
    }
}

#elif TARGET_OS_MAC

- (void)_addRenderTimer {
    if (!_displayTimer) {
        self.displayTimer =
            [NSTimer timerWithTimeInterval:1.0 / 60.0 target:self selector:@selector(draw) userInfo:nil repeats:YES];

        [[NSRunLoop mainRunLoop] addTimer:self.displayTimer forMode:NSRunLoopCommonModes];
    }
}

- (void)_removeRenderTimer {
    if (_displayTimer) {
        [_displayTimer invalidate];
        self.displayTimer = nil;
        self.renderPassDescriptor = nil;
    }
}

#endif

- (void)_updateTimerPaused {
    if (_paused || !self.superview) {
        [self _removeRenderTimer];
    } else {
        [self _addRenderTimer];
    }
}

- (void)_setNeedsUpdateDrawableSize {
    _needsUpdateDrawableSize = YES;
}

@end

NS_ASSUME_NONNULL_END
