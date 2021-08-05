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
    std::shared_ptr<sample::main> _main;
    observing::canceller_pool _pool;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    auto const metal_system = ui::metal_system::make_shared(
        objc_ptr_with_move_object(MTLCreateSystemDefaultDevice()).object(), self.metalView);

    self->_main = sample::main::make_shared([self view_look], metal_system);

    [self configure_with_metal_system:metal_system
                             renderer:self->_main->standard->renderer()
                        event_manager:self->_main->standard->event_manager()];

    self->_main->setup();

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
