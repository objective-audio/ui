//
//  yas_ui_metal_render_encoder_tests.mm
//

#import <XCTest/XCTest.h>
#import <iostream>
#import "yas_objc_ptr.h"
#import "yas_test_metal_view_controller.h"
#import "yas_ui.h"
#import "yas_ui_metal_encode_info.h"
#import "yas_ui_metal_render_encoder.h"

using namespace yas;

@interface yas_ui_metal_render_encoder_tests : XCTestCase

@end

@implementation yas_ui_metal_render_encoder_tests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [[YASTestMetalViewController sharedViewController] setRenderable:nullptr];
    [super tearDown];
}

- (void)test_create {
    ui::metal_render_encoder encoder;

    XCTAssertTrue(encoder.encodable());
}

- (void)test_create_null {
    ui::metal_render_encoder encoder{nullptr};

    XCTAssertFalse(encoder);
}

- (void)test_push_and_pop_encode_info {
    ui::metal_render_encoder encoder;

    encoder.push_encode_info({{nil, nil, nil}});

    XCTAssertEqual(encoder.all_encode_infos().size(), 1);

    auto encode_info1 = encoder.current_encode_info();
    XCTAssertTrue(encode_info1);

    encoder.push_encode_info({{nil, nil, nil}});

    XCTAssertEqual(encoder.all_encode_infos().size(), 2);

    auto encode_info2 = encoder.current_encode_info();
    XCTAssertTrue(encode_info2);

    encoder.pop_encode_info();

    XCTAssertEqual(encoder.all_encode_infos().size(), 2);
    XCTAssertEqual(encoder.current_encode_info(), encode_info1);

    encoder.pop_encode_info();

    XCTAssertEqual(encoder.all_encode_infos().size(), 2);
    XCTAssertFalse(encoder.current_encode_info());
}

- (void)test_append_mesh {
    ui::metal_render_encoder encoder;

    encoder.push_encode_info({{nil, nil, nil}});

    auto encode_info = encoder.current_encode_info();

    XCTAssertEqual(encode_info.meshes().size(), 0);

    ui::mesh mesh;
    encoder.encodable().append_mesh(mesh);

    XCTAssertEqual(encode_info.meshes().size(), 1);
    XCTAssertEqual(encode_info.meshes().at(0), mesh);
}

- (void)test_encode_smoke {
    auto device = make_objc_ptr(MTLCreateSystemDefaultDevice());
    if (!device) {
        std::cout << "skip : " << __PRETTY_FUNCTION__ << std::endl;
        return;
    }

    XCTestExpectation *expectation = [self expectationWithDescription:@"encode"];

    ui::renderer renderer{ui::metal_system{device.object()}};

    ui::action pre_render_action;

    pre_render_action.set_time_updater([&metal_system = renderer.metal_system(), expectation, self](auto const &) {
        auto mtlDevice = metal_system.testable().mtlDevice();

        auto view = [YASTestMetalViewController sharedViewController].metalView;
        XCTAssertNotNil(view.currentRenderPassDescriptor);

        auto const commandQueue = [mtlDevice newCommandQueue];
        auto const commandBuffer = [commandQueue commandBuffer];

        ui::metal_render_encoder encoder;

        ui::metal_encode_info encode_info{{view.currentRenderPassDescriptor,
                                           metal_system.testable().mtlRenderPipelineStateWithTexture(),
                                           metal_system.testable().mtlRenderPipelineStateWithoutTexture()}};

        encoder.push_encode_info(encode_info);

        ui::mesh mesh1;
        mesh1.set_mesh_data(ui::mesh_data{{.vertex_count = 1, .index_count = 1}});
        mesh1.metal().metal_setup(metal_system);
        encode_info.append_mesh(mesh1);

        ui::mesh mesh2;
        mesh2.set_mesh_data(ui::mesh_data{{.vertex_count = 1, .index_count = 1}});
        auto texture_result = ui::make_texture({.metal_system = metal_system, .point_size = {1, 1}});
        mesh2.set_texture(texture_result.value());
        mesh2.metal().metal_setup(metal_system);
        encode_info.append_mesh(mesh2);

        encoder.encode(metal_system, commandBuffer);

        [expectation fulfill];

        return true;
    });

    renderer.insert_action(pre_render_action);

    [[YASTestMetalViewController sharedViewController] setRenderable:renderer.view_renderable()];

    [self waitForExpectationsWithTimeout:1.0 handler:NULL];
}

@end
