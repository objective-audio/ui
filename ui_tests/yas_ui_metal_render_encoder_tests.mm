//
//  yas_ui_metal_render_encoder_tests.mm
//

#import <XCTest/XCTest.h>
#import <cpp_utils/yas_objc_ptr.h>
#import <ui/yas_ui_metal_encode_info.h>
#import <ui/yas_ui_metal_render_encoder.h>
#import <ui/yas_ui_umbrella.h>
#import <iostream>
#import "yas_test_metal_view_controller.h"

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
    auto encoder = ui::metal_render_encoder::make_shared();

    XCTAssertTrue(ui::render_encodable::cast(encoder));
}

- (void)test_push_and_pop_encode_info {
    auto encoder = ui::metal_render_encoder::make_shared();
    auto const stackable = ui::render_stackable::cast(encoder);

    stackable->push_encode_info(ui::metal_encode_info::make_shared({nil, nil, nil}));

    XCTAssertEqual(encoder->all_encode_infos().size(), 1);

    auto encode_info1 = stackable->current_encode_info();
    XCTAssertTrue(encode_info1);

    stackable->push_encode_info(ui::metal_encode_info::make_shared({nil, nil, nil}));

    XCTAssertEqual(encoder->all_encode_infos().size(), 2);

    auto encode_info2 = stackable->current_encode_info();
    XCTAssertTrue(encode_info2);

    stackable->pop_encode_info();

    XCTAssertEqual(encoder->all_encode_infos().size(), 2);
    XCTAssertEqual(stackable->current_encode_info(), encode_info1);

    stackable->pop_encode_info();

    XCTAssertEqual(encoder->all_encode_infos().size(), 2);
    XCTAssertFalse(stackable->current_encode_info());
}

- (void)test_append_mesh {
    auto encoder = ui::metal_render_encoder::make_shared();
    auto const stackable = ui::render_stackable::cast(encoder);

    stackable->push_encode_info(ui::metal_encode_info::make_shared({nil, nil, nil}));

    auto encode_info = stackable->current_encode_info();

    XCTAssertEqual(encode_info->meshes().size(), 0);

    auto mesh = ui::mesh::make_shared();
    ui::render_encodable::cast(encoder)->append_mesh(mesh);

    XCTAssertEqual(encode_info->meshes().size(), 1);
    XCTAssertEqual(encode_info->meshes().at(0), mesh);
}

- (void)test_encode_smoke {
    auto device = objc_ptr_with_move_object(MTLCreateSystemDefaultDevice());
    if (!device) {
        std::cout << "skip : " << __PRETTY_FUNCTION__ << std::endl;
        return;
    }

    XCTestExpectation *expectation = [self expectationWithDescription:@"encode"];

    auto renderer = ui::renderer::make_shared(ui::metal_system::make_shared(device.object()));

    auto pre_render_action = ui::action::make_shared();

    pre_render_action->set_time_updater([&metal_system = renderer->metal_system(), expectation, self](auto const &) {
        auto mtlDevice = ui::testable_metal_system::cast(metal_system)->mtlDevice();

        auto view = [YASTestMetalViewController sharedViewController].metalView;
        XCTAssertNotNil(view.currentRenderPassDescriptor);

        auto const commandQueue = [mtlDevice newCommandQueue];
        auto const commandBuffer = [commandQueue commandBuffer];

        auto encoder = ui::metal_render_encoder::make_shared();
        auto const stackable = ui::render_stackable::cast(encoder);

        auto encode_info = ui::metal_encode_info::make_shared(
            {view.currentRenderPassDescriptor,
             ui::testable_metal_system::cast(metal_system)->mtlRenderPipelineStateWithTexture(),
             ui::testable_metal_system::cast(metal_system)->mtlRenderPipelineStateWithoutTexture()});

        stackable->push_encode_info(encode_info);

        auto mesh1 = ui::mesh::make_shared();
        mesh1->set_mesh_data(ui::mesh_data::make_shared({.vertex_count = 1, .index_count = 1}));
        ui::metal_object::cast(mesh1)->metal_setup(metal_system);
        encode_info->append_mesh(mesh1);

        auto mesh2 = ui::mesh::make_shared();
        mesh2->set_mesh_data(ui::mesh_data::make_shared({.vertex_count = 1, .index_count = 1}));
        auto texture = ui::texture::make_shared({.point_size = {1, 1}});
        mesh2->set_texture(texture);
        ui::metal_object::cast(mesh2)->metal_setup(metal_system);
        encode_info->append_mesh(mesh2);

        encoder->encode(metal_system, commandBuffer);

        [expectation fulfill];

        return true;
    });

    renderer->insert_action(pre_render_action);

    [[YASTestMetalViewController sharedViewController] setRenderable:renderer->view_renderable()];

    [self waitForExpectationsWithTimeout:1.0 handler:NULL];
}

@end
