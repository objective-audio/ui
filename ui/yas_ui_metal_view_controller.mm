//
//  yas_ui_metal_view_controller.mm
//

#include "yas_ui_metal_view_controller.h"
#include <chaining/yas_chaining_umbrella.h>
#include <objc_utils/yas_objc_unowned.h>
#include "yas_ui_color.h"

NS_ASSUME_NONNULL_BEGIN

using namespace yas;

namespace yas::ui {
namespace metal_view {
    struct cpp_variables {
        ui::view_renderable_ptr renderable{nullptr};
        chaining::observer_pool pool;
    };
}
}

@interface YASUIMetalViewController () <MTKViewDelegate, YASUIMetalViewDelegate>

@end

@implementation YASUIMetalViewController {
    ui::metal_view::cpp_variables _cpp;
}

#if TARGET_OS_IPHONE
- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil {
#elif TARGET_OS_MAC
- (instancetype)initWithNibName:(nullable NSNibName)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil {
#endif
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
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
}

- (void)loadView {
    if (self.nibName || self.nibBundle) {
        [super loadView];
    } else {
        auto view = objc_ptr_with_move_object([[YASUIMetalView alloc] initWithFrame:CGRectZero device:nil]);
        self.view = view.object();
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];

#if (!TARGET_OS_IPHONE && TARGET_OS_MAC)
    [self.metalView addObserver:self
                     forKeyPath:@"effectiveAppearance"
                        options:NSKeyValueObservingOptionNew
                        context:nil];
#endif

    self.metalView.delegate = self;
    self.metalView.uiDelegate = self;
}

#if (!TARGET_OS_IPHONE && TARGET_OS_MAC)
- (void)dealloc {
    [self.metalView removeObserver:self forKeyPath:@"effectiveAppearance"];

    yas_super_dealloc();
}

- (void)observeValueForKeyPath:(nullable NSString *)keyPath
                      ofObject:(nullable id)object
                        change:(nullable NSDictionary<NSKeyValueChangeKey, id> *)change
                       context:(nullable void *)context {
    if ([keyPath isEqualToString:@"effectiveAppearance"]) {
        [self appearanceDidChange:self.metalView.uiAppearance];
    }
}
#endif

#if TARGET_OS_IPHONE
- (void)traitCollectionDidChange:(nullable UITraitCollection *)previousTraitCollection {
    if (self.traitCollection.userInterfaceStyle != previousTraitCollection.userInterfaceStyle) {
        [self appearanceDidChange:self.metalView.uiAppearance];
    }
}
#endif

- (void)appearanceDidChange:(yas::ui::appearance)appearance {
    if (self->_cpp.renderable && self.metalView) {
        self->_cpp.renderable->view_appearance_did_change(self.metalView, appearance);
    }
}

- (YASUIMetalView *)metalView {
    return (YASUIMetalView *)self.view;
}

- (void)setRenderable:(yas::ui::view_renderable_ptr const &)renderable {
    self->_cpp.renderable = renderable;

    if (renderable) {
        renderable->view_configure(self.metalView);

        auto unowned = [[YASUnownedObject<YASUIMetalViewController *> alloc] initWithObject:self];
        renderable->clear_color()
            ->chain()
            .perform([unowned](auto const &color) {
                unowned.object.metalView.clearColor = MTLClearColorMake(color.red, color.green, color.blue, 1.0);
            })
            .sync()
            ->add_to(self->_cpp.pool);
    } else {
        self.metalView.device = nil;
        self->_cpp.pool.invalidate();
    }
}

- (yas::ui::view_renderable_ptr const &)renderable {
    return self->_cpp.renderable;
}

#pragma mark -

- (void)setPaused:(BOOL)pause {
    self.metalView.paused = pause;
}

- (BOOL)isPaused {
    return self.metalView.isPaused;
}

#pragma mark - MTKViewDelegate

- (void)mtkView:(YASUIMetalView *)view drawableSizeWillChange:(CGSize)size {
    if (self->_cpp.renderable && self.metalView) {
        self->_cpp.renderable->view_size_will_change(self.metalView, size);
    }
}

- (void)drawInMTKView:(YASUIMetalView *)view {
    if (self->_cpp.renderable && self.metalView) {
        self->_cpp.renderable->view_render(self.metalView);
    }
}

#pragma mark - YASUIMetalViewDelegate

- (void)uiMetalView:(YASUIMetalView *)view safeAreaInsetsDidChange:(yas_edge_insets)insets {
    if (self->_cpp.renderable && self.metalView) {
        self->_cpp.renderable->view_safe_area_insets_did_change(self.metalView, insets);
    }
}

@end

NS_ASSUME_NONNULL_END
