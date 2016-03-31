//
//  yas_ui_metal_view_controller_tests.mm
//

#import <XCTest/XCTest.h>
#import "yas_ui_metal_view.h"
#import "yas_ui_metal_view_controller.h"

@interface yas_ui_metal_view_controller_mac_tests : XCTestCase

@property (nonatomic, strong) NSWindow *window;
@property (nonatomic, strong) YASUIMetalViewController *viewController;

@end

@implementation yas_ui_metal_view_controller_mac_tests

- (void)setUp {
    [super setUp];

    self.viewController = [[YASUIMetalViewController alloc] initWithNibName:nil bundle:nil];

    self.window = [NSWindow windowWithContentViewController:self.viewController];
    self.window.styleMask = NSBorderlessWindowMask;

    yas_release(self.viewController);
}

- (void)tearDown {
    self.viewController = nil;
    self.window = nil;

    [super tearDown];
}

- (void)test_create {
    auto viewController = self.viewController;

    XCTAssertFalse(viewController.paused);

    auto metalView = viewController.metalView;
    XCTAssertNotNil(metalView);
    XCTAssertEqualObjects([metalView class], [YASUIMetalView class]);
}

- (void)test_set_frame {
    XCTAssertTrue(CGRectEqualToRect(self.viewController.metalView.frame, CGRectZero));

    [self.window setFrame:CGRectMake(10, 100, 256, 128) display:YES];

    XCTAssertTrue(CGRectEqualToRect(self.viewController.metalView.frame, CGRectMake(0, 0, 256, 128)));
}

- (void)test_set_pause {
    self.viewController.paused = YES;

    XCTAssertTrue(self.viewController.paused);
}

@end
