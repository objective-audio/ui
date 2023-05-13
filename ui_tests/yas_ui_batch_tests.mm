//
//  yas_ui_batch_tests.mm
//

#import <Metal/Metal.h>
#import <XCTest/XCTest.h>
#import <cpp_utils/yas_objc_ptr.h>
#import <ui/yas_ui_umbrella.h>
#import <iostream>
#import <sstream>
#import "yas_ui_view_look_stubs.h"

using namespace yas;
using namespace yas::ui;

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
    auto batch = batch::make_shared();

    XCTAssertTrue(batch);

    XCTAssertTrue(renderable_batch::cast(batch));
    XCTAssertTrue(render_encodable::cast(batch));
}

- (void)test_render_mesh_building {
    auto device = objc_ptr_with_move_object(MTLCreateSystemDefaultDevice());
    if (!device) {
        std::cout << "skip : " << __PRETTY_FUNCTION__ << std::endl;
        return;
    }

    auto batch = batch::make_shared();
    auto batch_renderable = renderable_batch::cast(batch);
    auto batch_encodable = render_encodable::cast(batch);

    batch_renderable->begin_render_meshes_building(batch_building_type::rebuild);

    auto mesh1 =
        mesh::make_shared({}, static_mesh_vertex_data::make_shared(1), static_mesh_index_data::make_shared(1), nullptr);
    auto mesh2 =
        mesh::make_shared({}, static_mesh_vertex_data::make_shared(1), static_mesh_index_data::make_shared(1), nullptr);
    batch_encodable->append_mesh(mesh1);
    batch_encodable->append_mesh(mesh2);

    auto const metal_system = metal_system::make_shared(device.object(), nil);
    auto const view_look = view_look_scale_factor_stub::make_shared(1.0);

    auto const vertex_data3 = static_mesh_vertex_data::make_shared(1);
    auto const index_data3 = static_mesh_index_data::make_shared(1);

    auto const mesh3 = mesh::make_shared({}, vertex_data3, index_data3, nullptr);
    auto texture3 = texture::make_shared(texture_args{}, view_look);
    mesh3->set_texture(texture3);
    batch_encodable->append_mesh(mesh3);

    mesh1->metal_setup(metal_system);
    mesh2->metal_setup(metal_system);
    mesh3->metal_setup(metal_system);

    batch_renderable->commit_render_meshes_building();

    auto const &meshes = batch_renderable->meshes();
    XCTAssertEqual(meshes.size(), 2);
    XCTAssertFalse(meshes.at(0)->texture());
    XCTAssertTrue(meshes.at(1)->texture());
    XCTAssertEqual(meshes.at(1)->texture(), texture3);

    batch_renderable->clear_render_meshes();

    XCTAssertEqual(meshes.size(), 0);
}

- (void)test_mesh_batching {
    auto device = objc_ptr_with_move_object(MTLCreateSystemDefaultDevice());
    if (!device) {
        std::cout << "skip : " << __PRETTY_FUNCTION__ << std::endl;
        return;
    }

    auto metal_system = metal_system::make_shared(device.object(), nil);

    auto batch = batch::make_shared();
    auto batch_renderable = renderable_batch::cast(batch);
    auto batch_encodable = render_encodable::cast(batch);

    auto vertex_data1 = static_mesh_vertex_data::make_shared(1);
    auto index_data1 = static_mesh_index_data::make_shared(1);
    vertex_data1->write_once([](std::vector<vertex2d_t> &vertices) {
        auto &vertex = vertices.at(0);
        vertex.position.x = 1.0f;
        vertex.position.y = 1.0f;
        vertex.tex_coord.x = 1.0f;
        vertex.tex_coord.y = 1.0f;
    });
    index_data1->write_once([](std::vector<index2d_t> &indices) {
        auto &index = indices.at(0);
        index = 1;
    });
    auto mesh1 = mesh::make_shared({.color = {0.5f, 0.5f, 0.5f, 0.5f}}, vertex_data1, index_data1, nullptr);

    auto vertex_data2 = static_mesh_vertex_data::make_shared(1);
    auto index_data2 = static_mesh_index_data::make_shared(1);
    vertex_data2->write_once([](std::vector<vertex2d_t> &vertices) {
        auto &vertex = vertices.at(0);
        vertex.position.x = 2.0f;
        vertex.position.y = 2.0f;
        vertex.tex_coord.x = 2.0f;
        vertex.tex_coord.y = 2.0f;
        vertex.color[0] = 2.0f;
        vertex.color[1] = 2.0f;
        vertex.color[2] = 2.0f;
        vertex.color[3] = 2.0f;
    });
    index_data2->write_once([](std::vector<index2d_t> &indices) {
        auto &index = indices.at(0);
        index = 1;
    });
    auto mesh2 = mesh::make_shared({.use_mesh_color = true}, vertex_data2, index_data2, nullptr);

    mesh1->metal_setup(metal_system);
    mesh2->metal_setup(metal_system);

    batch_renderable->begin_render_meshes_building(batch_building_type::rebuild);

    batch_encodable->append_mesh(mesh1);
    batch_encodable->append_mesh(mesh2);

    batch_renderable->commit_render_meshes_building();

    auto &meshes = batch_renderable->meshes();
    XCTAssertEqual(meshes.size(), 1);

    auto const &render_mesh = meshes.at(0);
    auto const &render_vertex_data = render_mesh->vertex_data();
    auto const &render_index_data = render_mesh->index_data();

    XCTAssertEqual(renderable_mesh::cast(render_mesh)->render_vertex_count(), 2);
    XCTAssertEqual(renderable_mesh::cast(render_mesh)->render_index_count(), 2);
    XCTAssertEqual(render_vertex_data->count(), 2);
    XCTAssertEqual(render_index_data->count(), 2);

    auto const *vertices = render_vertex_data->raw_data();
    auto const *indices = render_index_data->raw_data();

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
    auto device = objc_ptr_with_move_object(MTLCreateSystemDefaultDevice());
    if (!device) {
        std::cout << "skip : " << __PRETTY_FUNCTION__ << std::endl;
        return;
    }

    auto metal_system = metal_system::make_shared(device.object(), nil);

    auto batch = batch::make_shared();
    auto batch_renderable = renderable_batch::cast(batch);
    auto batch_encodable = render_encodable::cast(batch);

    auto const vertex_data = dynamic_mesh_vertex_data::make_shared(1);
    auto const index_data = dynamic_mesh_index_data::make_shared(1);
    auto const mesh = mesh::make_shared({}, vertex_data, index_data, nullptr);

    mesh->metal_setup(metal_system);

    vertex_data->write([](std::vector<vertex2d_t> &vertices) { vertices.at(0).position.x = 1.0f; });
    index_data->write([](std::vector<index2d_t> &indices) { indices.at(0) = 3; });

    batch_renderable->begin_render_meshes_building(batch_building_type::rebuild);
    batch_encodable->append_mesh(mesh);
    batch_renderable->commit_render_meshes_building();

    auto &meshes = batch_renderable->meshes();
    XCTAssertEqual(meshes.size(), 1);

    auto const &render_mesh = meshes.at(0);
    auto const &render_vertex_data = render_mesh->vertex_data();
    auto const &render_index_data = render_mesh->index_data();
    auto const *vertices = render_vertex_data->raw_data();
    auto const *indices = render_index_data->raw_data();

    XCTAssertEqual(vertices[0].position.x, 1.0f);
    XCTAssertEqual(indices[0], 3);

    vertex_data->write([](std::vector<vertex2d_t> &vertices) { vertices.at(0).position.x = 11.0f; });
    index_data->write([](std::vector<index2d_t> &indices) { indices.at(0) = 13; });

    batch_renderable->begin_render_meshes_building(batch_building_type::overwrite);
    batch_renderable->commit_render_meshes_building();

    XCTAssertEqual(vertices[0].position.x, 11.0f);
    XCTAssertEqual(indices[0], 13);
}

- (void)test_metal_setup {
    auto device = objc_ptr_with_move_object(MTLCreateSystemDefaultDevice());
    if (!device) {
        std::cout << "skip : " << __PRETTY_FUNCTION__ << std::endl;
        return;
    }

    auto metal_system = metal_system::make_shared(device.object(), nil);

    auto batch = batch::make_shared();
    auto batch_renderable = renderable_batch::cast(batch);
    auto batch_encodable = render_encodable::cast(batch);

    auto const vertex_data = static_mesh_vertex_data::make_shared(1);
    auto const index_data = static_mesh_index_data::make_shared(1);
    auto mesh = mesh::make_shared({}, vertex_data, index_data, nullptr);

    mesh->metal_setup(metal_system);

    batch_renderable->begin_render_meshes_building(batch_building_type::rebuild);

    batch_encodable->append_mesh(mesh);

    batch_renderable->commit_render_meshes_building();

    XCTAssertTrue(batch->metal_setup(metal_system));
}

- (void)test_batch_building_type_to_string {
    XCTAssertEqual(to_string(batch_building_type::rebuild), "rebuild");
    XCTAssertEqual(to_string(batch_building_type::overwrite), "overwrite");
    XCTAssertEqual(to_string(batch_building_type::none), "none");
}

- (void)test_batch_building_type_ostream {
    auto const types = {batch_building_type::rebuild, batch_building_type::overwrite, batch_building_type::none};

    for (auto const &type : types) {
        std::ostringstream stream;
        stream << type;
        XCTAssertEqual(stream.str(), to_string(type));
    }
}

@end
