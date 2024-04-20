//
//  yas_test_metal_view_controller.mm
//

#import "yas_test_metal_view_controller.h"

@interface YASTestMetalViewController ()

@end

@implementation YASTestMetalViewController

- (void)viewDidLoad {
    [super viewDidLoad];

#if TARGET_OS_IPHONE
    self.view.multipleTouchEnabled = YES;
#endif
}

@end
