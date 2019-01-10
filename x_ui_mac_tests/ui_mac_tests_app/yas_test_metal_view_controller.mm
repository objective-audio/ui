//
//  yas_test_metal_view_controller.mm
//

#import "yas_test_metal_view_controller.h"

static __weak YASTestMetalViewController *_shared = nil;

@interface YASTestMetalViewController ()

@end

@implementation YASTestMetalViewController

+ (instancetype)sharedViewController {
    return _shared;
}

#if TARGET_OS_IPHONE
- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil {
#elif TARGET_OS_MAC
- (instancetype)initWithNibName:(nullable NSNibName)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil {
#endif
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _shared = self;
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        _shared = self;
    }
    return self;
}

- (void)dealloc {
    _shared = nil;
    yas_super_dealloc();
}

- (void)viewDidLoad {
    [super viewDidLoad];

#if TARGET_OS_IPHONE
    self.view.multipleTouchEnabled = YES;
#endif
}

@end
