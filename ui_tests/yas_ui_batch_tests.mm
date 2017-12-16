//
//  yas_ui_batch_tests.mm
//

#import <Metal/Metal.h>
#import <XCTest/XCTest.h>
#import <iostream>
#import <sstream>
#import "yas_objc_ptr.h"
#import "yas_ui_batch.h"
#import "yas_ui_batch_protocol.h"
#import "yas_ui_mesh.h"
#import "yas_ui_mesh_data.h"
#import "yas_ui_metal_system.h"
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

- (void)test_render_mesh_building {
    auto device = make_objc_ptr(MTLCreateSystemDefaultDevice());
    if (!device) {
        std::cout << "skip : " << __PRETTY_FUNCTION__ << std::endl;
        return;
    }

    ui::batch batch;

    batch.renderable().begin_render_meshes_building(ui::batch_building_type::rebuild);

    ui::mesh mesh1;
    ui::mesh mesh2;
    batch.encodable().append_mesh(mesh1);
    batch.encodable().append_mesh(mesh2);

    ui::metal_system metal_system{device.object()};

    ui::mesh mesh3;
    auto texture3 = ui::make_texture({.metal_system = metal_system}).value();
    mesh3.set_texture(texture3);
    batch.encodable().append_mesh(mesh3);

    batch.renderable().commit_render_meshes_building();

    auto const &meshes = batch.renderable().meshes();
    XCTAssertEqual(meshes.size(), 2);
    XCTAssertFalse(meshes.at(0).texture());
    XCTAssertTrue(meshes.at(1).texture());
    XCTAssertEqual(meshes.at(1).texture(), texture3);

    batch.renderable().clear_render_meshes();

    XCTAssertEqual(meshes.size(), 0);
}

- (void)test_mesh_batching {
    auto device = make_objc_ptr(MTLCreateSystemDefaultDevice());
    if (!device) {
        std::cout << "skip : " << __PRETTY_FUNCTION__ << std::endl;
        return;
    }

    ui::metal_system metal_system{device.object()};

    ui::batch batch;

    ui::mesh mesh1;
    mesh1.set_color({0.5f, 0.5f, 0.5f, 0.5f});
    ui::mesh_data mesh_data1{{.vertex_count = 1, .index_count = 1}};
    mesh_data1.write([](std::vector<ui::vertex2d_t> &vertices, std::vector<ui::index2d_t> &indices) {
        auto &vertex = vertices.at(0);
        vertex.position.x = 1.0f;
        vertex.position.y = 1.0f;
        vertex.tex_coord.x = 1.0f;
        vertex.tex_coord.y = 1.0f;

        auto &index = indices.at(0);
        index = 1;
    });
    mesh1.set_mesh_data(mesh_data1);

    ui::mesh mesh2;
    mesh2.set_use_mesh_color(true);
    ui::mesh_data mesh_data2{{.vertex_count = 1, .index_count = 1}};
    mesh_data2.write([](std::vector<ui::vertex2d_t> &vertices, std::vector<ui::index2d_t> &indices) {
        auto &vertex = vertices.at(0);
        vertex.position.x = 2.0f;
        vertex.position.y = 2.0f;
        vertex.tex_coord.x = 2.0f;
        vertex.tex_coord.y = 2.0f;
        vertex.color[0] = 2.0f;
        vertex.color[1] = 2.0f;
        vertex.color[2] = 2.0f;
        vertex.color[3] = 2.0f;

        auto &index = indices.at(0);
        index = 1;
    });
    mesh2.set_mesh_data(mesh_data2);

    mesh1.metal().metal_setup(metal_system);
    mesh2.metal().metal_setup(metal_system);

    batch.renderable().begin_render_meshes_building(ui::batch_building_type::rebuild);

    batch.encodable().append_mesh(mesh1);
    batch.encodable().append_mesh(mesh2);

    batch.renderable().commit_render_meshes_building();

    auto &meshes = batch.renderable().meshes();
    XCTAssertEqual(meshes.size(), 1);

    auto &render_mesh = meshes.at(0);
    auto &render_mesh_data = render_mesh.mesh_data();

    XCTAssertEqual(render_mesh.renderable().render_vertex_count(), 2);
    XCTAssertEqual(render_mesh.renderable().render_index_count(), 2);
    XCTAssertEqual(render_mesh_data.vertex_count(), 2);
    XCTAssertEqual(render_mesh_data.index_count(), 2);

    auto const *vertices = render_mesh_data.vertices();
    auto const *indices = render_mesh_data.indices();

    XCTAssertEqual(vertices[0].position.x, 1.0f);
    XCTAssertEqual(vertices[0].position.y, 1.0f);
    XCTAssertEqual(vertices[0].tex_coord.x, 1.0f);
    XCTAssertEqual(vertices[0].tex_coord.y, 1.0f);
    XCTAssertEqual(vertices[0].color[0], 0.5f);
    XCTAssertEqual(vertices[0].color[1], 0.5f);
    XCTAssertEqual(vertices[0].color[2], 0.5f);
    XCTAssertEqual(vertices[0].color[3], 0.5f);
    XCTAssertEqual(indices[0], 1);

    XCTAssertEqual(vertices[1].position.x, 2.0f);
    XCTAssertEqual(vertices[1].position.y, 2.0f);
    XCTAssertEqual(vertices[1].tex_coord.x, 2.0f);
    XCTAssertEqual(vertices[1].tex_coord.y, 2.0f);
    XCTAssertEqual(vertices[1].color[0], 2.0f);
    XCTAssertEqual(vertices[1].color[1], 2.0f);
    XCTAssertEqual(vertices[1].color[2], 2.0f);
    XCTAssertEqual(vertices[1].color[3], 2.0f);
    XCTAssertEqual(indices[1], 2);
}

- (void)test_overwrite {
    auto device = make_objc_ptr(MTLCreateSystemDefaultDevice());
    if (!device) {
        std::cout << "skip : " << __PRETTY_FUNCTION__ << std::endl;
        return;
    }

    ui::metal_system metal_system{device.object()};

    ui::batch batch;

    ui::mesh mesh;
    ui::dynamic_mesh_data mesh_data{{.vertex_count = 1, .index_count = 1}};
    mesh.set_mesh_data(mesh_data);

    mesh.metal().metal_setup(metal_system);

    mesh_data.write([](std::vector<ui::vertex2d_t> &vertices, std::vector<ui::index2d_t> &indices) {
        vertices.at(0).position.x = 1.0f;
        indices.at(0) = 3;
    });

    batch.renderable().begin_render_meshes_building(ui::batch_building_type::rebuild);
    batch.encodable().append_mesh(mesh);
    batch.renderable().commit_render_meshes_building();

    auto &meshes = batch.renderable().meshes();
    XCTAssertEqual(meshes.size(), 1);

    auto &render_mesh = meshes.at(0);
    auto &render_mesh_data = render_mesh.mesh_data();
    auto const *vertices = render_mesh_data.vertices();
    auto const *indices = render_mesh_data.indices();

    XCTAssertEqual(vertices[0].position.x, 1.0f);
    XCTAssertEqual(indices[0], 3);

    mesh_data.write([](std::vector<ui::vertex2d_t> &vertices, std::vector<ui::index2d_t> &indices) {
        vertices.at(0).position.x = 11.0f;
        indices.at(0) = 13;
    });

    batch.renderable().begin_render_meshes_building(ui::batch_building_type::overwrite);
    batch.renderable().commit_render_meshes_building();

    XCTAssertEqual(vertices[0].position.x, 11.0f);
    XCTAssertEqual(indices[0], 13);
}

- (void)test_metal_setup {
    auto device = make_objc_ptr(MTLCreateSystemDefaultDevice());
    if (!device) {
        std::cout << "skip : " << __PRETTY_FUNCTION__ << std::endl;
        return;
    }

    ui::metal_system metal_system{device.object()};

    ui::batch batch;

    ui::mesh mesh;
    ui::mesh_data mesh_data{{.vertex_count = 1, .index_count = 1}};
    mesh.set_mesh_data(mesh_data);

    mesh.metal().metal_setup(metal_system);

    batch.renderable().begin_render_meshes_building(ui::batch_building_type::rebuild);

    batch.encodable().append_mesh(mesh);

    batch.renderable().commit_render_meshes_building();

    XCTAssertTrue(batch.metal().metal_setup(metal_system));
}

- (void)test_batch_building_type_to_string {
    XCTAssertEqual(to_string(ui::batch_building_type::rebuild), "rebuild");
    XCTAssertEqual(to_string(ui::batch_building_type::overwrite), "overwrite");
    XCTAssertEqual(to_string(ui::batch_building_type::none), "none");
}

- (void)test_batch_building_type_ostream {
    auto const types = {ui::batch_building_type::rebuild, ui::batch_building_type::overwrite,
                        ui::batch_building_type::none};

    for (auto const &type : types) {
        std::ostringstream stream;
        stream << type;
        XCTAssertEqual(stream.str(), to_string(type));
    }
}

@end
