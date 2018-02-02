//
//  yas_ui_metal_view_controller.mm
//

#include "yas_objc_ptr.h"
#include "yas_ui_metal_view_controller.h"

NS_ASSUME_NONNULL_BEGIN

using namespace yas;

namespace yas::ui {
namespace metal_view {
    struct cpp_variables {
        ui::view_renderable renderable{nullptr};
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
        auto view = make_objc_ptr([[YASUIMetalView alloc] initWithFrame:CGRectZero device:nil]);
        self.view = view.object();
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.metalView.delegate = self;
    self.metalView.uiDelegate = self;
}

- (YASUIMetalView *)metalView {
    return (YASUIMetalView *)self.view;
}

- (void)setRenderable:(yas::ui::view_renderable)renderable {
    self->_cpp.renderable = renderable;

    if (renderable) {
        renderable.configure(self.metalView);
    } else {
        self.metalView.device = nil;
    }
}

- (yas::ui::view_renderable const &)renderable {
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
        self->_cpp.renderable.size_will_change(self.metalView, size);
    }
}

- (void)drawInMTKView:(YASUIMetalView *)view {
    if (self->_cpp.renderable && self.metalView) {
        self->_cpp.renderable.render(self.metalView);
    }
}

#pragma mark - YASUIMetalViewDelegate

- (void)uiMetalView:(YASUIMetalView *)view safeAreaInsetsDidChange:(yas_edge_insets)insets {
    if (self->_cpp.renderable && self.metalView) {
        self->_cpp.renderable.safe_area_insets_did_change(self.metalView, insets);
    }
}

@end

NS_ASSUME_NONNULL_END
