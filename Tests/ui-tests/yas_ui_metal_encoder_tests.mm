//
//  yas_ui_metal_encoder_tests.mm
//

#import <XCTest/XCTest.h>
#import <cpp-utils/objc_ptr.h>
#import <ui/yas_ui_umbrella.h>
#import <iostream>
#import "yas_test_metal_view_controller.h"
#import "yas_ui_view_look_stubs.h"

#if (!TARGET_OS_IPHONE && TARGET_OS_MAC)

using namespace yas;
using namespace yas::ui;

@interface yas_ui_metal_encoder_tests : XCTestCase
@property (nonatomic, strong) NSWindow *window;
@property (nonatomic, strong) YASTestMetalViewController *testViewController;
@end

@implementation yas_ui_metal_encoder_tests

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
    auto encoder = metal_encoder::make_shared();

    XCTAssertTrue(render_encodable::cast(encoder));
}

- (void)test_push_and_pop_encode_info {
    auto encoder = metal_encoder::make_shared();
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
    auto encoder = metal_encoder::make_shared();
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

    auto const metal_system = metal_system::make_shared(device.object(), nil);
    auto const view_look = view_look_scale_factor_stub::make_shared(1.0);
    auto const root_node = ui::node::make_shared();
    auto const detector = ui::detector::make_shared();
    auto const action_manager = ui::action_manager::make_shared();
    auto const renderer =
        renderer::make_shared(metal_system, ui::view_look::make_shared(), root_node, detector, action_manager);

    auto time_updater = [&metal_system, &view_look, expectation, &self](auto const &, auto const &) {
        std::shared_ptr<metal_system_for_view> const view_metal_system = metal_system;
        auto mtlDevice = view_metal_system->mtlDevice();

        auto view = self.testViewController.metalView;
        XCTAssertNotNil(view.currentRenderPassDescriptor);

        auto const commandQueue = [mtlDevice newCommandQueue];
        auto const commandBuffer = [commandQueue commandBuffer];

        auto encoder = metal_encoder::make_shared();
        auto const stackable = render_stackable::cast(encoder);

        auto mesh1 = mesh::make_shared({}, static_mesh_vertex_data::make_shared(1),
                                       static_mesh_index_data::make_shared(1), nullptr);
        mesh1->metal_setup(metal_system);

        auto mesh2 = mesh::make_shared({}, static_mesh_vertex_data::make_shared(1),
                                       static_mesh_index_data::make_shared(1), nullptr);
        auto texture = texture::make_shared({.point_size = {1, 1}}, view_look);
        mesh2->set_texture(texture);
        mesh2->metal_setup(metal_system);

        encoder->encode(metal_system, commandBuffer);

        [expectation fulfill];

        return true;
    };

    auto pre_render_action = action::make_shared({.time_updater = std::move(time_updater)});

    action_manager->insert_action(pre_render_action);

    [self.testViewController configure_with_metal_system:metal_system renderer:renderer event_manager:nullptr];

    [self waitForExpectations:@[expectation] timeout:1.0];
}

@end

#endif
