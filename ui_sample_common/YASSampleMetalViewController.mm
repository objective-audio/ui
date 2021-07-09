//
//  YASSampleMetalViewController.mm
//

#import "YASSampleMetalViewController.h"
#import "yas_sample_main.h"

using namespace yas;
using namespace yas::ui;

@interface YASSampleMetalViewController ()
@end

@implementation YASSampleMetalViewController {
    sample::main _main;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [self setRenderer:_main.renderer];
    [self set_event_manager:_main.event_manager];

    self->_main.setup();

#if TARGET_OS_IPHONE
    self.view.multipleTouchEnabled = YES;
#endif
}

#if TARGET_OS_IPHONE
- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}
#endif

@end
