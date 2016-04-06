//
//  yas_ui_metal_view_controller_tests.mm
//

#import <XCTest/XCTest.h>
#import "yas_objc_ptr.h"
#import "yas_ui_metal_view_controller.h"

using namespace yas;

@interface yas_ui_metal_view_controller_mac_tests : XCTestCase

@end

@implementation yas_ui_metal_view_controller_mac_tests {
    objc_ptr<NSWindow *> _window;
    objc_ptr<YASUIMetalViewController *> _view_controller;
}

- (void)setUp {
    [super setUp];

    _view_controller.move_object([[YASUIMetalViewController alloc] initWithNibName:nil bundle:nil]);
    _window = make_objc_ptr<NSWindow *>([viewController = _view_controller.object()]() {
        NSWindow *window = [NSWindow windowWithContentViewController:viewController];
        window.styleMask = NSBorderlessWindowMask;
        return window;
    });
}

- (void)tearDown {
    _view_controller.set_object(nil);
    _window.set_object(nil);

    [super tearDown];
}

- (void)test_create {
    auto viewController = _view_controller.object();

    XCTAssertFalse(viewController.paused);

    auto metalView = viewController.metalView;
    XCTAssertNotNil(metalView);
    XCTAssertEqualObjects([metalView class], [MTKView class]);
}

- (void)test_set_frame {
    auto viewController = _view_controller.object();
    auto window = _window.object();

    XCTAssertTrue(CGRectEqualToRect(viewController.metalView.frame, CGRectZero));

    [window setFrame:CGRectMake(10, 100, 256, 128) display:YES];

    XCTAssertTrue(CGRectEqualToRect(viewController.metalView.frame, CGRectMake(0, 0, 256, 128)));
}

- (void)test_set_pause {
    auto viewController = _view_controller.object();

    viewController.paused = YES;

    XCTAssertTrue(viewController.paused);
}

@end
