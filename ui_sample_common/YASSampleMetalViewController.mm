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

#if TARGET_OS_IPHONE
    self.view.multipleTouchEnabled = YES;
    _main.setup(self.view.layer.contentsScale);
#elif TARGET_OS_MAC
    _main.setup([NSScreen mainScreen].backingScaleFactor);
#endif

    [self setRenderer:_main.renderer.view_renderable()];
}

@end
