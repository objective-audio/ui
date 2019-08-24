//
//  YASSampleMetalViewController.mm
//

#import "YASSampleMetalViewController.h"
#import "yas_sample_main.h"

using namespace yas;

@interface YASSampleMetalViewController ()
@end

@implementation YASSampleMetalViewController {
    sample::main _main;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [self setRenderable:_main.renderer->view_renderable()];

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
