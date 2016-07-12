//
//  yas_ui_metal_view_controller_tests.mm
//

#import <XCTest/XCTest.h>
#import <iostream>
#import "yas_objc_ptr.h"
#import "yas_test_metal_view_controller.h"
#import "yas_ui_metal_view_controller.h"

using namespace yas;

@interface yas_ui_metal_view_controller_mac_tests : XCTestCase

@end

@implementation yas_ui_metal_view_controller_mac_tests {
}

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [[YASTestMetalViewController sharedViewController] setRenderable:nullptr];
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

- (void)test_renderable {
    auto device = make_objc_ptr(MTLCreateSystemDefaultDevice());
    if (!device) {
        std::cout << "skip : " << __PRETTY_FUNCTION__ << std::endl;
        return;
    }

    ui::renderer renderer{ui::metal_system{device.object()}};

    auto viewController = [YASTestMetalViewController sharedViewController];

    XCTAssertFalse(viewController.renderable);

    [viewController setRenderable:renderer.view_renderable()];

    XCTAssertTrue(viewController.renderable);
}

- (void)test_drawable_size_will_change {
    auto device = make_objc_ptr(MTLCreateSystemDefaultDevice());
    if (!device) {
        std::cout << "skip : " << __PRETTY_FUNCTION__ << std::endl;
        return;
    }

    ui::renderer renderer{ui::metal_system{device.object()}};

    auto viewController = [YASTestMetalViewController sharedViewController];

    [viewController.view.window setFrame:CGRectMake(0, 0, 16, 16) display:YES];

    XCTAssertEqual(renderer.view_size(), (ui::uint_size{0, 0}));

    [viewController setRenderable:renderer.view_renderable()];

    XCTAssertEqual(renderer.view_size(), (ui::uint_size{16, 16}));

    XCTestExpectation *expectation = [self expectationWithDescription:@"view_size_changed"];

    auto observer = renderer.subject().make_observer(ui::renderer::method::view_size_changed,
                                                     [expectation](auto const &context) mutable {
                                                         [expectation fulfill];
                                                         expectation = nil;
                                                     });

    [viewController.view.window setFrame:CGRectMake(0, 0, 32, 32) display:YES];

    [self waitForExpectationsWithTimeout:1.0 handler:NULL];

    XCTAssertEqual(renderer.view_size(), (ui::uint_size{32, 32}));
}

@end
