//
//  yas_ui_metal_encode_info_tests.mm
//

#import <XCTest/XCTest.h>
#import <cpp_utils/yas_objc_ptr.h>
#import <ui/ui.h>
#import <iostream>
#import "yas_test_metal_view_controller.h"

using namespace yas;

@interface yas_ui_metal_encode_info_tests : XCTestCase

@end

@implementation yas_ui_metal_encode_info_tests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [[YASTestMetalViewController sharedViewController] setRenderer:nullptr];
    [super tearDown];
}

- (void)test_create {
    auto info = ui::metal_encode_info::make_shared({nil, nil, nil});

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

    auto metal_system = ui::metal_system::make_shared(device.object());
    auto renderer = ui::renderer::make_shared(metal_system);

    auto time_updater = [expectation, &self, &metal_system](auto const &, auto const &) mutable {
        auto view = [YASTestMetalViewController sharedViewController].metalView;
        XCTAssertNotNil(view.currentRenderPassDescriptor);

        auto info = ui::metal_encode_info::make_shared(
            {view.currentRenderPassDescriptor,
             ui::testable_metal_system::cast(metal_system)->mtlRenderPipelineStateWithTexture(),
             ui::testable_metal_system::cast(metal_system)->mtlRenderPipelineStateWithoutTexture()});

        XCTAssertEqualObjects(info->renderPassDescriptor(), view.currentRenderPassDescriptor);
        XCTAssertEqualObjects(info->pipelineStateWithTexture(),
                              ui::testable_metal_system::cast(metal_system)->mtlRenderPipelineStateWithTexture());
        XCTAssertEqualObjects(info->pipelineStateWithoutTexture(),
                              ui::testable_metal_system::cast(metal_system)->mtlRenderPipelineStateWithoutTexture());

        [expectation fulfill];

        return true;
    };

    auto pre_render_action = ui::action::make_shared({.time_updater = std::move(time_updater)});

    renderer->insert_action(pre_render_action);

    [[YASTestMetalViewController sharedViewController] setRenderer:renderer];

    [self waitForExpectationsWithTimeout:1.0 handler:NULL];
}

- (void)test_set_mesh {
    auto info = ui::metal_encode_info::make_shared({nil, nil, nil});

    info->append_mesh(ui::mesh::make_shared());

    XCTAssertEqual(info->meshes().size(), 1);

    info->append_mesh(ui::mesh::make_shared());

    XCTAssertEqual(info->meshes().size(), 2);
}

@end
