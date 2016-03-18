//
//  yas_ui_metal_view_controller.mm
//

#import "yas_ui_metal_view.h"
#import "yas_ui_metal_view_controller.h"

NS_ASSUME_NONNULL_BEGIN

@interface YASMetalViewController ()

@end

@implementation YASMetalViewController

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
        auto view = [[YASMetalView alloc] initWithFrame:CGRectZero];
        self.view = view;
        yas_release(view);
    }
}

- (YASMetalView *)metalView {
    return (YASMetalView *)self.view;
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
