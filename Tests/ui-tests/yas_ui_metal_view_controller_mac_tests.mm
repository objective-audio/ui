//
//  yas_ui_metal_view_controller_tests.mm
//

#import <XCTest/XCTest.h>
#import <cpp-utils/objc_ptr.h>
#import <ui/yas_ui_umbrella.h>
#import <iostream>
#import "yas_test_metal_view_controller.h"

#if (!TARGET_OS_IPHONE && TARGET_OS_MAC)

using namespace yas;
using namespace yas::ui;

@interface yas_ui_metal_view_controller_mac_tests : XCTestCase
@property (nonatomic, strong) NSWindow *window;
@property (nonatomic, strong) YASTestMetalViewController *testViewController;
@end

@implementation yas_ui_metal_view_controller_mac_tests {
}

- (void)setUp {
    [super setUp];
    self.testViewController = [[YASTestMetalViewController alloc] init];
    self.window = [NSWindow windowWithContentViewController:self.testViewController];
    self.window.styleMask = self.window.styleMask & ~NSWindowStyleMaskTitled;
}

- (void)tearDown {
    self.testViewController = nil;
    self.window = nil;
    [super tearDown];
}

- (void)test_create {
    auto viewController = self.testViewController;

    XCTAssertFalse(viewController.paused);

    auto metalView = viewController.metalView;
    XCTAssertNotNil(metalView);
    XCTAssertEqualObjects([metalView class], [YASUIMetalView class]);
}

- (void)test_set_frame {
    auto viewController = self.testViewController;

    [viewController.view.window setFrame:CGRectMake(10, 100, 256, 128) display:YES];

    XCTAssertTrue(CGRectEqualToRect(viewController.metalView.frame, CGRectMake(0, 0, 256, 128)));
}

- (void)test_set_pause {
    auto viewController = self.testViewController;

    viewController.paused = YES;

    XCTAssertTrue(viewController.paused);
}

- (void)test_renderer {
    auto device = objc_ptr_with_move_object(MTLCreateSystemDefaultDevice());
    if (!device) {
        std::cout << "skip : " << __PRETTY_FUNCTION__ << std::endl;
        return;
    }

    auto const view_look = ui::view_look::make_shared();
    auto const renderer =
        renderer::make_shared(metal_system::make_shared(device.object(), nil), view_look, nullptr, nullptr, nullptr);

    auto viewController = self.testViewController;

    XCTAssertFalse(viewController.renderer);

    [self.testViewController configure_with_metal_system:nullptr renderer:renderer event_manager:nullptr];

    XCTAssertTrue(viewController.renderer);
}

@end

#endif
