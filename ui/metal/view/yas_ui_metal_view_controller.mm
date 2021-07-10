//
//  yas_ui_metal_view_controller.mm
//

#include "yas_ui_metal_view_controller.h"
#include <objc_utils/yas_objc_unowned.h>
#include <observing/yas_observing_umbrella.h>
#include <ui/yas_ui_color.h>
#include <ui/yas_ui_view_look.h>

NS_ASSUME_NONNULL_BEGIN

using namespace yas;

namespace yas::ui {
struct metal_view_cpp {
    std::shared_ptr<view_look> const view_look = ui::view_look::make_shared();
    std::shared_ptr<view_renderer_interface> renderable{nullptr};
};
}

@interface YASUIMetalViewController () <MTKViewDelegate, YASUIMetalViewDelegate>

@end

@implementation YASUIMetalViewController {
    ui::metal_view_cpp _cpp;
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

- (std::shared_ptr<yas::ui::view_look> const &)view_look {
    return self->_cpp.view_look;
}

- (void)set_renderer:(std::shared_ptr<yas::ui::view_renderer_interface> const &)renderable {
    self->_cpp.renderable = renderable;

    if (renderable) {
        renderable->view_configure(self.metalView);
    } else {
        self.metalView.device = nil;
    }
}

- (std::shared_ptr<yas::ui::view_renderer_interface> const &)renderer {
    return self->_cpp.renderable;
}

- (void)set_event_manager:(std::shared_ptr<yas::ui::metal_view_event_manager_interface> const &)event_manager {
    [self.metalView set_event_manager:event_manager];
}

- (std::shared_ptr<yas::ui::metal_view_event_manager_interface> const &)event_manager {
    return [self.metalView event_manager];
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

- (void)uiMetalView:(YASUIMetalView *)view safeAreaInsetsDidChange:(ui::region_insets)insets {
    if (self->_cpp.renderable && self.metalView) {
        self->_cpp.renderable->view_safe_area_insets_did_change(self.metalView, insets);
    }
}

@end

NS_ASSUME_NONNULL_END
