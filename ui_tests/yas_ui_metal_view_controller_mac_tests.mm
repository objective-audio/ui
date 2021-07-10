//
//  yas_ui_metal_view_controller_tests.mm
//

#import <XCTest/XCTest.h>
#import <cpp_utils/yas_objc_ptr.h>
#import <ui/ui.h>
#import <iostream>
#import "yas_test_metal_view_controller.h"

using namespace yas;
using namespace yas::ui;

@interface yas_ui_metal_view_controller_mac_tests : XCTestCase

@end

@implementation yas_ui_metal_view_controller_mac_tests {
}

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [[YASTestMetalViewController sharedViewController] set_renderer:nullptr];
    [[YASTestMetalViewController sharedViewController] set_event_manager:nullptr];
    [super tearDown];
}

- (void)test_create {
    auto viewController = [YASTestMetalViewController sharedViewController];

    XCTAssertFalse(viewController.paused);

    auto metalView = viewController.metalView;
    XCTAssertNotNil(metalView);
    XCTAssertEqualObjects([metalView class], [YASUIMetalView class]);
}

- (void)test_set_frame {
    auto viewController = [YASTestMetalViewController sharedViewController];

    [viewController.view.window setFrame:CGRectMake(10, 100, 256, 128) display:YES];

    XCTAssertTrue(CGRectEqualToRect(viewController.metalView.frame, CGRectMake(0, 0, 256, 128)));
}

- (void)test_set_pause {
    auto viewController = [YASTestMetalViewController sharedViewController];

    viewController.paused = YES;

    XCTAssertTrue(viewController.paused);
}

- (void)test_renderer {
    auto device = objc_ptr_with_move_object(MTLCreateSystemDefaultDevice());
    if (!device) {
        std::cout << "skip : " << __PRETTY_FUNCTION__ << std::endl;
        return;
    }

    auto renderer = renderer::make_shared(metal_system::make_shared(device.object()), nullptr, nullptr);

    auto viewController = [YASTestMetalViewController sharedViewController];

    XCTAssertFalse(viewController.renderer);

    [viewController set_renderer:renderer];

    XCTAssertTrue(viewController.renderer);
}

- (void)test_drawable_size_will_change {
    auto device = objc_ptr_with_move_object(MTLCreateSystemDefaultDevice());
    if (!device) {
        std::cout << "skip : " << __PRETTY_FUNCTION__ << std::endl;
        return;
    }

    auto renderer = renderer::make_shared(metal_system::make_shared(device.object()), nullptr, nullptr);

    auto viewController = [YASTestMetalViewController sharedViewController];

    [viewController.view.window setFrame:CGRectMake(0, 0, 16, 16) display:YES];

    XCTAssertEqual(renderer->view_size(), (uint_size{0, 0}));

    [viewController set_renderer:renderer];

    XCTAssertEqual(renderer->view_size(), (uint_size{16, 16}));

    XCTestExpectation *expectation = [self expectationWithDescription:@"view_size_changed"];

    auto canceller = renderer->view_layout_guide()
                         ->observe([&expectation](region const &) {
                             [expectation fulfill];
                             expectation = nil;
                         })
                         .end();

    [viewController.view.window setFrame:CGRectMake(0, 0, 32, 32) display:YES];

    [self waitForExpectationsWithTimeout:1.0 handler:NULL];

    XCTAssertEqual(renderer->view_size(), (uint_size{32, 32}));
}

@end
