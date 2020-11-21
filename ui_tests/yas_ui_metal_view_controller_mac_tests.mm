//
//  yas_ui_metal_view_controller_tests.mm
//

#import <XCTest/XCTest.h>
#import <cpp_utils/yas_objc_ptr.h>
#import <ui/ui.h>
#import <iostream>
#import "yas_test_metal_view_controller.h"

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
    auto device = objc_ptr_with_move_object(MTLCreateSystemDefaultDevice());
    if (!device) {
        std::cout << "skip : " << __PRETTY_FUNCTION__ << std::endl;
        return;
    }

    auto renderer = ui::renderer::make_shared(ui::metal_system::make_shared(device.object()));

    auto viewController = [YASTestMetalViewController sharedViewController];

    XCTAssertFalse(viewController.renderable);

    [viewController setRenderable:renderer];

    XCTAssertTrue(viewController.renderable);
}

- (void)test_drawable_size_will_change {
    auto device = objc_ptr_with_move_object(MTLCreateSystemDefaultDevice());
    if (!device) {
        std::cout << "skip : " << __PRETTY_FUNCTION__ << std::endl;
        return;
    }

    auto renderer = ui::renderer::make_shared(ui::metal_system::make_shared(device.object()));

    auto viewController = [YASTestMetalViewController sharedViewController];

    [viewController.view.window setFrame:CGRectMake(0, 0, 16, 16) display:YES];

    XCTAssertEqual(renderer->view_size(), (ui::uint_size{0, 0}));

    [viewController setRenderable:renderer];

    XCTAssertEqual(renderer->view_size(), (ui::uint_size{16, 16}));

    XCTestExpectation *expectation = [self expectationWithDescription:@"view_size_changed"];

    auto observer = renderer->view_layout_guide_rect()
                        ->chain()
                        .perform([&expectation](ui::region const &) {
                            [expectation fulfill];
                            expectation = nil;
                        })
                        .end();

    [viewController.view.window setFrame:CGRectMake(0, 0, 32, 32) display:YES];

    [self waitForExpectationsWithTimeout:1.0 handler:NULL];

    XCTAssertEqual(renderer->view_size(), (ui::uint_size{32, 32}));
}

@end
