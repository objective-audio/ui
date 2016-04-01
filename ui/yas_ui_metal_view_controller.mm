//
//  yas_ui_metal_view_controller.mm
//

#import "yas_objc_ptr.h"
#import "yas_ui_metal_view.h"
#import "yas_ui_metal_view_controller.h"

NS_ASSUME_NONNULL_BEGIN

using namespace yas;

@interface YASUIMetalViewController ()

@end

@implementation YASUIMetalViewController

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
        auto view = make_objc_ptr([[YASUIMetalView alloc] initWithFrame:CGRectZero]);
        self.view = view.object();
    }
}

- (YASUIMetalView *)metalView {
    return (YASUIMetalView *)self.view;
}

#pragma mark -

- (void)setPaused:(BOOL)pause {
    self.metalView.paused = pause;
}

- (BOOL)isPaused {
    return self.metalView.isPaused;
}

@end

NS_ASSUME_NONNULL_END
