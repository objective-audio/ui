//
//  yas_ui_metal_encode_info_tests.mm
//

#import <XCTest/XCTest.h>
#import <cpp-utils/objc_ptr.h>
#import <ui/yas_ui_umbrella.h>
#import <iostream>
#import "yas_test_metal_view_controller.h"

#if (!TARGET_OS_IPHONE && TARGET_OS_MAC)

using namespace yas;
using namespace yas::ui;

@interface yas_ui_metal_encode_info_tests : XCTestCase
@property (nonatomic, strong) NSWindow *window;
@property (nonatomic, strong) YASTestMetalViewController *testViewController;
@end

@implementation yas_ui_metal_encode_info_tests

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
    auto info = metal_encode_info::make_shared({nil, nil, nil});

    XCTAssertTrue(info);

    XCTAssertNil(info->renderPassDescriptor());
    XCTAssertNil(info->pipelineStateWithTexture());
    XCTAssertNil(info->pipelineStateWithoutTexture());
    XCTAssertEqual(info->meshes().size(), 0);
}

- (void)test_create_with_parameters {
    auto device = objc_ptr_with_move_object(MTLCreateSystemDefaultDevice());
    if (!device) {
        std::cout << "skip : " << __PRETTY_FUNCTION__ << std::endl;
        return;
    }

    XCTestExpectation *expectation = [self expectationWithDescription:@"create_with_parameters"];

    auto metal_system = metal_system::make_shared(device.object(), nil);
    auto root_node = ui::node::make_shared();
    auto detector = ui::detector::make_shared();
    auto action_manager = ui::action_manager::make_shared();
    auto renderer =
        renderer::make_shared(metal_system, ui::view_look::make_shared(), root_node, detector, action_manager);

    auto time_updater = [expectation, self, &metal_system](auto const &, auto const &) mutable {
        auto view = self.testViewController.metalView;
        XCTAssertNotNil(view.currentRenderPassDescriptor);

        [expectation fulfill];

        return true;
    };

    auto pre_render_action = action::make_shared({.time_updater = std::move(time_updater)});

    action_manager->insert_action(pre_render_action);

    [self.testViewController configure_with_metal_system:metal_system renderer:renderer event_manager:nullptr];

    [self waitForExpectations:@[expectation] timeout:1.0];
}

- (void)test_set_mesh {
    auto info = metal_encode_info::make_shared({nil, nil, nil});

    info->append_mesh(mesh::make_shared());

    XCTAssertEqual(info->meshes().size(), 1);

    info->append_mesh(mesh::make_shared());

    XCTAssertEqual(info->meshes().size(), 2);
}

@end

#endif
