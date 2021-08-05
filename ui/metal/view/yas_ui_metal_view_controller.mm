//
//  yas_ui_metal_view_controller.mm
//

#include "yas_ui_metal_view_controller.h"
#include <objc_utils/yas_objc_unowned.h>
#include <observing/yas_observing_umbrella.h>
#include <ui/yas_ui_background.h>
#include <ui/yas_ui_color.h>
#include <ui/yas_ui_metal_system.h>
#include <ui/yas_ui_metal_view_controller_dependency.h>
#include <ui/yas_ui_metal_view_controller_dependency_objc.h>
#include <ui/yas_ui_metal_view_utils.h>
#include <ui/yas_ui_view_look.h>

NS_ASSUME_NONNULL_BEGIN

using namespace yas;
using namespace yas::ui;

namespace yas::ui {
struct metal_view_cpp {
    std::shared_ptr<view_look> const view_look = ui::view_look::make_shared();
    std::shared_ptr<view_renderer_interface> renderer{nullptr};
    observing::canceller_pool bg_pool;
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

    [self updateViewLookSizesWithDrawableSize:self.metalView.drawableSize];
    self->_cpp.view_look->set_appearance(self.metalView.uiAppearance);

    self->_cpp.view_look->background()
        ->observe_color([self](ui::color const &) { [self updateBackgroundColor]; })
        .end()
        ->add_to(self->_cpp.bg_pool);

    self->_cpp.view_look->background()
        ->observe_alpha([self](float const &) { [self updateBackgroundColor]; })
        .sync()
        ->add_to(self->_cpp.bg_pool);
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
    self->_cpp.view_look->set_appearance(appearance);
}

- (YASUIMetalView *)metalView {
    return (YASUIMetalView *)self.view;
}

- (std::shared_ptr<yas::ui::view_look> const &)view_look {
    return self->_cpp.view_look;
}

- (void)configure_with_metal_system:(std::shared_ptr<yas::ui::view_metal_system_interface> const &)metal_system
                           renderer:(std::shared_ptr<yas::ui::view_renderer_interface> const &)renderer
                      event_manager:
                          (std::shared_ptr<yas::ui::metal_view_event_manager_interface> const &)event_manager {
    if (metal_system) {
        self.metalView.device = metal_system->mtlDevice();
        self.metalView.sampleCount = metal_system->sample_count();
    } else {
        self.metalView.device = nil;
        self.metalView.sampleCount = 1;
    }

    self->_cpp.renderer = renderer;

    [self.metalView set_event_manager:event_manager];
}

- (std::shared_ptr<yas::ui::view_renderer_interface> const &)renderer {
    return self->_cpp.renderer;
}

#pragma mark -

- (void)setPaused:(BOOL)pause {
    self.metalView.paused = pause;
}

- (BOOL)isPaused {
    return self.metalView.isPaused;
}

#pragma mark - MTKViewDelegate

- (void)mtkView:(YASUIMetalView *)view drawableSizeWillChange:(CGSize)drawable_size {
    [self updateViewLookSizesWithDrawableSize:drawable_size];
}

- (void)drawInMTKView:(YASUIMetalView *)view {
    if (self->_cpp.renderer) {
        self->_cpp.renderer->view_render();
    }
}

#pragma mark - YASUIMetalViewDelegate

- (void)uiMetalView:(YASUIMetalView *)view safeAreaInsetsDidChange:(ui::region_insets)insets {
    self->_cpp.view_look->set_safe_area_insets(insets);
}

#pragma mark - Private

- (void)updateViewLookSizesWithDrawableSize:(CGSize)drawable_size {
    self->_cpp.view_look->set_view_sizes(metal_view_utils::to_uint_size(self.view.bounds.size),
                                         metal_view_utils::to_uint_size(drawable_size),
                                         self.metalView.uiSafeAreaInsets);
}

- (void)updateBackgroundColor {
    auto const &background = self->_cpp.view_look->background();
    auto const &color = background->color();
    auto const &alpha = background->alpha();
    self.metalView.clearColor = MTLClearColorMake(color.red, color.green, color.blue, alpha);
}

@end

NS_ASSUME_NONNULL_END
