//
//  yas_ui_metal_render_encoder_tests.mm
//

#import <XCTest/XCTest.h>
#import <cpp_utils/yas_objc_ptr.h>
#import <ui/ui.h>
#import <iostream>
#import "yas_test_metal_view_controller.h"

using namespace yas;
using namespace yas::ui;

@interface yas_ui_metal_render_encoder_tests : XCTestCase

@end

@implementation yas_ui_metal_render_encoder_tests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [[YASTestMetalViewController sharedViewController] configure_with_metal_system:nullptr renderer:nullptr];
    [[YASTestMetalViewController sharedViewController] set_event_manager:nullptr];
    [super tearDown];
}

- (void)test_create {
    auto encoder = metal_render_encoder::make_shared();

    XCTAssertTrue(render_encodable::cast(encoder));
}

- (void)test_push_and_pop_encode_info {
    auto encoder = metal_render_encoder::make_shared();
    auto const stackable = render_stackable::cast(encoder);

    stackable->push_encode_info(metal_encode_info::make_shared({nil, nil, nil}));

    XCTAssertEqual(encoder->all_encode_infos().size(), 1);

    auto encode_info1 = stackable->current_encode_info();
    XCTAssertTrue(encode_info1);

    stackable->push_encode_info(metal_encode_info::make_shared({nil, nil, nil}));

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
    auto encoder = metal_render_encoder::make_shared();
    auto const stackable = render_stackable::cast(encoder);

    stackable->push_encode_info(metal_encode_info::make_shared({nil, nil, nil}));

    auto encode_info = stackable->current_encode_info();

    XCTAssertEqual(encode_info->meshes().size(), 0);

    auto mesh = mesh::make_shared();
    render_encodable::cast(encoder)->append_mesh(mesh);

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

    auto const metal_system = metal_system::make_shared(device.object());
    auto const root_node = ui::node::make_shared();
    auto const detector = ui::detector::make_shared();
    auto const action_manager = ui::action_manager::make_shared();
    auto const renderer =
        renderer::make_shared(metal_system, ui::view_look::make_shared(), root_node, detector, action_manager);

    auto time_updater = [&metal_system, expectation, &self](auto const &, auto const &) {
        std::shared_ptr<view_metal_system_interface> const view_metal_system = metal_system;
        auto mtlDevice = view_metal_system->mtlDevice();

        auto view = [YASTestMetalViewController sharedViewController].metalView;
        XCTAssertNotNil(view.currentRenderPassDescriptor);

        auto const commandQueue = [mtlDevice newCommandQueue];
        auto const commandBuffer = [commandQueue commandBuffer];

        auto encoder = metal_render_encoder::make_shared();
        auto const stackable = render_stackable::cast(encoder);

        auto encode_info = metal_encode_info::make_shared(
            {view.currentRenderPassDescriptor,
             testable_metal_system::cast(metal_system)->mtlRenderPipelineStateWithTexture(),
             testable_metal_system::cast(metal_system)->mtlRenderPipelineStateWithoutTexture()});

        stackable->push_encode_info(encode_info);

        auto mesh1 = mesh::make_shared();
        mesh1->set_mesh_data(mesh_data::make_shared({.vertex_count = 1, .index_count = 1}));
        metal_object::cast(mesh1)->metal_setup(metal_system);
        encode_info->append_mesh(mesh1);

        auto mesh2 = mesh::make_shared();
        mesh2->set_mesh_data(mesh_data::make_shared({.vertex_count = 1, .index_count = 1}));
        auto texture = texture::make_shared({.point_size = {1, 1}});
        mesh2->set_texture(texture);
        metal_object::cast(mesh2)->metal_setup(metal_system);
        encode_info->append_mesh(mesh2);

        encoder->encode(metal_system, commandBuffer);

        [expectation fulfill];

        return true;
    };

    auto pre_render_action = action::make_shared({.time_updater = std::move(time_updater)});

    action_manager->insert_action(pre_render_action);

    [[YASTestMetalViewController sharedViewController] configure_with_metal_system:nullptr renderer:renderer];

    [self waitForExpectationsWithTimeout:1.0 handler:NULL];
}

@end
