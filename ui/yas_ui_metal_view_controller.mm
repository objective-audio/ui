//
//  yas_ui_metal_view_controller.mm
//

#import "yas_objc_ptr.h"
#import "yas_ui_metal_view_controller.h"

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

@interface YASUIMetalViewController () <MTKViewDelegate>

@end

@implementation YASUIMetalViewController {
    ui::metal_view::cpp_variables _cpp;
}

- (nullable instancetype)initWithNibName:(nullable NSString *)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil {
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
        auto view = make_objc_ptr([[MTKView alloc] initWithFrame:CGRectZero device:nil]);
        self.view = view.object();
    }

    auto device = make_objc_ptr(MTLCreateSystemDefaultDevice());
    self.metalView.device = device.object();
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.metalView.delegate = self;
}

- (MTKView *)metalView {
    return (MTKView *)self.view;
}

- (void)setRenderer:(yas::ui::view_renderable)renderer {
    _cpp.renderer = renderer;
    renderer.configure(self.metalView);
}

- (yas::ui::view_renderable const &)renderer {
    return _cpp.renderer;
}

#pragma mark -

- (void)setPaused:(BOOL)pause {
    self.metalView.paused = pause;
}

- (BOOL)isPaused {
    return self.metalView.isPaused;
}

#pragma mark - MTKViewDelegate

- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size {
    if (_cpp.renderer && self.metalView) {
        _cpp.renderer.drawable_size_will_change(self.metalView, size);
    }
}

- (void)drawInMTKView:(MTKView *)view {
    if (_cpp.renderer && self.metalView) {
        _cpp.renderer.render(self.metalView);
    }
}

@end

NS_ASSUME_NONNULL_END
