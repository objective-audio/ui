//
//  yas_ui_metal_encode_info_tests.mm
//

#import <XCTest/XCTest.h>
#import <iostream>
#import "yas_objc_ptr.h"
#import "yas_test_metal_view_controller.h"
#import "yas_ui.h"
#import "yas_ui_metal_encode_info.h"

using namespace yas;

@interface yas_ui_metal_encode_info_tests : XCTestCase

@end

@implementation yas_ui_metal_encode_info_tests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [[YASTestMetalViewController sharedViewController] setRenderable:nullptr];
    [super tearDown];
}

- (void)test_create {
    ui::metal_encode_info info{{nil, nil, nil}};

    XCTAssertTrue(info);

    XCTAssertNil(info.renderPassDescriptor());
    XCTAssertNil(info.pipelineStateWithTexture());
    XCTAssertNil(info.pipelineStateWithoutTexture());
    XCTAssertEqual(info.meshes().size(), 0);
}

- (void)test_create_with_parameters {
    auto device = make_objc_ptr(MTLCreateSystemDefaultDevice());
    if (!device) {
        std::cout << "skip : " << __PRETTY_FUNCTION__ << std::endl;
        return;
    }

    XCTestExpectation *expectation = [self expectationWithDescription:@"create_with_parameters"];

    ui::metal_system metal_system{device.object()};
    ui::renderer renderer{metal_system};

    ui::action pre_render_action;
    
    pre_render_action.set_time_updater([expectation, self, &metal_system](auto const &) mutable {
        auto view = [YASTestMetalViewController sharedViewController].metalView;
        XCTAssertNotNil(view.currentRenderPassDescriptor);

        ui::metal_encode_info info{{view.currentRenderPassDescriptor,
                                    metal_system.testable().mtlRenderPipelineStateWithTexture(),
                                    metal_system.testable().mtlRenderPipelineStateWithoutTexture()}};

        XCTAssertEqualObjects(info.renderPassDescriptor(), view.currentRenderPassDescriptor);
        XCTAssertEqualObjects(info.pipelineStateWithTexture(),
                              metal_system.testable().mtlRenderPipelineStateWithTexture());
        XCTAssertEqualObjects(info.pipelineStateWithoutTexture(),
                              metal_system.testable().mtlRenderPipelineStateWithoutTexture());

        [expectation fulfill];

        return true;
    });
    
    renderer.insert_action(pre_render_action);

    [[YASTestMetalViewController sharedViewController] setRenderable:renderer.view_renderable()];

    [self waitForExpectationsWithTimeout:1.0 handler:NULL];
}

- (void)test_create_null {
    ui::metal_encode_info info{nullptr};

    XCTAssertFalse(info);
}

- (void)test_set_mesh {
    ui::metal_encode_info info{{nil, nil, nil}};

    info.append_mesh(ui::mesh{});

    XCTAssertEqual(info.meshes().size(), 1);

    info.append_mesh(ui::mesh{});

    XCTAssertEqual(info.meshes().size(), 2);
}

@end
