//
//  yas_ui_batch_tests.mm
//

#import <Metal/Metal.h>
#import <XCTest/XCTest.h>
#import <iostream>
#import "yas_objc_ptr.h"
#import "yas_ui_batch.h"
#import "yas_ui_batch_protocol.h"
#import "yas_ui_mesh.h"
#import "yas_ui_node.h"
#import "yas_ui_texture.h"

using namespace yas;

@interface yas_ui_batch_tests : XCTestCase

@end

@implementation yas_ui_batch_tests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)test_create {
    ui::batch batch;

    XCTAssertTrue(batch);

    XCTAssertTrue(batch.renderable());
    XCTAssertTrue(batch.encodable());
    XCTAssertTrue(batch.metal());
}

- (void)test_create_null {
    ui::batch batch{nullptr};

    XCTAssertFalse(batch);
}

- (void)test_mesh_batching {
    auto device = make_objc_ptr(MTLCreateSystemDefaultDevice());
    if (!device) {
        std::cout << "skip : " << __PRETTY_FUNCTION__ << std::endl;
        return;
    }

    ui::batch batch;

    batch.renderable().begin_render_meshes_building(ui::batch_building_type::rebuild);

    ui::mesh mesh1;
    ui::mesh mesh2;
    batch.encodable().push_back_mesh(mesh1);
    batch.encodable().push_back_mesh(mesh2);

    ui::mesh mesh3;
    auto texture3 = ui::make_texture({.device = device.object()}).value();
    mesh3.set_texture(texture3);
    batch.encodable().push_back_mesh(mesh3);

    batch.renderable().commit_render_meshes_building();

    auto const &meshes = batch.renderable().meshes();
    XCTAssertEqual(meshes.size(), 2);
    XCTAssertFalse(meshes.at(0).texture());
    XCTAssertTrue(meshes.at(1).texture());
    XCTAssertEqual(meshes.at(1).texture(), texture3);
}

- (void)test_batch_building_type_to_string {
    XCTAssertEqual(to_string(ui::batch_building_type::rebuild), "rebuild");
    XCTAssertEqual(to_string(ui::batch_building_type::overwrite), "overwrite");
    XCTAssertEqual(to_string(ui::batch_building_type::none), "none");
}

- (void)test_batch_building_type_ostream {
    std::cout << ui::batch_building_type::rebuild << std::endl;
    std::cout << ui::batch_building_type::overwrite << std::endl;
    std::cout << ui::batch_building_type::none << std::endl;
}

@end
