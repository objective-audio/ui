//
//  yas_ui_mesh_tests.mm
//

#import <XCTest/XCTest.h>
#import <cpp-utils/each_index.h>
#import <cpp-utils/objc_ptr.h>
#import <ui/yas_ui_umbrella.h>
#import <iostream>
#import <sstream>
#import "yas_ui_view_look_stubs.h"

using namespace yas;
using namespace yas::ui;

@interface yas_ui_mesh_tests : XCTestCase

@end

@implementation yas_ui_mesh_tests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)test_create_mesh {
    auto mesh = mesh::make_shared();

    XCTAssertFalse(mesh->vertex_data());
    XCTAssertFalse(mesh->index_data());
    XCTAssertFalse(mesh->texture());
    XCTAssertEqual(mesh->color().v[0], 1.0f);
    XCTAssertEqual(mesh->color().v[1], 1.0f);
    XCTAssertEqual(mesh->color().v[2], 1.0f);
    XCTAssertEqual(mesh->color().v[3], 1.0f);
    XCTAssertEqual(mesh->primitive_type(), primitive_type::triangle);
    XCTAssertFalse(mesh->is_use_mesh_color());

    auto matrix = renderable_mesh::cast(mesh)->matrix();
    auto identity_matrix = matrix_identity_float4x4;
    for (auto const &col : each_index<std::size_t>(4)) {
        for (auto const &row : each_index<std::size_t>(4)) {
            XCTAssertEqual(matrix.columns[col][row], identity_matrix.columns[col][row]);
        }
    }

    XCTAssertTrue(renderable_mesh::cast(mesh));
}

- (void)test_set_mesh_variables {
    auto device = objc_ptr_with_move_object(MTLCreateSystemDefaultDevice());
    if (!device) {
        std::cout << "skip : " << __PRETTY_FUNCTION__ << std::endl;
        return;
    }

    auto vertex_data = static_mesh_vertex_data::make_shared(4);
    auto index_data = static_mesh_index_data::make_shared(6);
    auto mesh = mesh::make_shared({}, nullptr, nullptr, nullptr);

    auto const metal_system = metal_system::make_shared(device.object(), nil);
    auto const view_look = view_look_scale_factor_stub::make_shared(1.0);

    auto texture = texture::make_shared({.point_size = {16, 8}}, view_look);

    mesh->set_vertex_data(vertex_data);
    mesh->set_index_data(index_data);
    mesh->set_texture(texture);
    mesh->set_color({0.1f, 0.2f, 0.3f, 0.4f});
    mesh->set_primitive_type(primitive_type::point);
    mesh->set_use_mesh_color(true);

    XCTAssertEqual(mesh->texture(), texture);
    XCTAssertEqual(mesh->color().v[0], 0.1f);
    XCTAssertEqual(mesh->color().v[1], 0.2f);
    XCTAssertEqual(mesh->color().v[2], 0.3f);
    XCTAssertEqual(mesh->color().v[3], 0.4f);
    XCTAssertEqual(mesh->vertex_data(), vertex_data);
    XCTAssertEqual(mesh->index_data(), index_data);
    XCTAssertEqual(mesh->primitive_type(), primitive_type::point);
    XCTAssertTrue(mesh->is_use_mesh_color());
}

- (void)test_mesh_const_variables {
    auto device = objc_ptr_with_move_object(MTLCreateSystemDefaultDevice());
    if (!device) {
        std::cout << "skip : " << __PRETTY_FUNCTION__ << std::endl;
        return;
    }

    auto const metal_system = metal_system::make_shared(device.object(), nil);
    auto const view_look = view_look_scale_factor_stub::make_shared(1.0);

    auto texture = texture::make_shared({.point_size = {16, 8}}, view_look);

    auto vertex_data = static_mesh_vertex_data::make_shared(4);
    auto index_data = static_mesh_index_data::make_shared(6);
    auto mesh = mesh::make_shared({}, vertex_data, index_data, texture);

    std::shared_ptr<ui::mesh const> const_mesh = mesh;

    XCTAssertEqual(const_mesh->texture(), texture);
    XCTAssertEqual(const_mesh->vertex_data(), vertex_data);
    XCTAssertEqual(const_mesh->index_data(), index_data);
}

- (void)test_set_renderable_variables {
    auto mesh = mesh::make_shared();

    auto const renderable = renderable_mesh::cast(mesh);

    simd::float4x4 matrix;
    matrix.columns[0] = {1.0f, 2.0f, 3.0f, 4.0f};
    matrix.columns[1] = {5.0f, 6.0f, 7.0f, 8.0f};
    matrix.columns[2] = {9.0f, 10.0f, 11.0f, 12.0f};
    matrix.columns[3] = {13.0f, 14.0f, 15.0f, 16.0f};

    renderable->set_matrix(matrix);

    XCTAssertEqual(renderable->matrix().columns[0][0], 1.0f);
    XCTAssertEqual(renderable->matrix().columns[0][1], 2.0f);
    XCTAssertEqual(renderable->matrix().columns[0][2], 3.0f);
    XCTAssertEqual(renderable->matrix().columns[0][3], 4.0f);

    XCTAssertEqual(renderable->matrix().columns[1][0], 5.0f);
    XCTAssertEqual(renderable->matrix().columns[1][1], 6.0f);
    XCTAssertEqual(renderable->matrix().columns[1][2], 7.0f);
    XCTAssertEqual(renderable->matrix().columns[1][3], 8.0f);

    XCTAssertEqual(renderable->matrix().columns[2][0], 9.0f);
    XCTAssertEqual(renderable->matrix().columns[2][1], 10.0f);
    XCTAssertEqual(renderable->matrix().columns[2][2], 11.0f);
    XCTAssertEqual(renderable->matrix().columns[2][3], 12.0f);

    XCTAssertEqual(renderable->matrix().columns[3][0], 13.0f);
    XCTAssertEqual(renderable->matrix().columns[3][1], 14.0f);
    XCTAssertEqual(renderable->matrix().columns[3][2], 15.0f);
    XCTAssertEqual(renderable->matrix().columns[3][3], 16.0f);
}

- (void)test_mesh_setup_metal_buffer_constant {
    auto const vertex_data = static_mesh_vertex_data::make_shared(4);
    auto const index_data = static_mesh_index_data::make_shared(6);

    auto device = objc_ptr_with_move_object(MTLCreateSystemDefaultDevice());
    if (!device) {
        std::cout << "skip : " << __PRETTY_FUNCTION__ << std::endl;
        return;
    }

    auto metal_system = metal_system::make_shared(device.object(), nil);

    XCTAssertNil(vertex_data->mtlBuffer());
    XCTAssertNil(index_data->mtlBuffer());

    auto vertex_setup_result = vertex_data->metal_setup(metal_system);
    XCTAssertTrue(vertex_setup_result);

    if (!vertex_setup_result) {
        std::cout << "setup_error::" << to_string(vertex_setup_result.error()) << std::endl;
    }

    auto index_setup_result = index_data->metal_setup(metal_system);
    XCTAssertTrue(index_setup_result);

    if (!index_setup_result) {
        std::cout << "setup_error::" << to_string(index_setup_result.error()) << std::endl;
    }

    XCTAssertNotNil(vertex_data->mtlBuffer());
    XCTAssertNotNil(index_data->mtlBuffer());
    XCTAssertEqual(vertex_data->mtlBuffer().length, 4 * sizeof(vertex2d_t));
    XCTAssertEqual(index_data->mtlBuffer().length, 6 * sizeof(index2d_t));
}

- (void)test_mesh_setup_metal_buffer_dynamic {
    auto const vertex_data = dynamic_mesh_vertex_data::make_shared(4);
    auto const index_data = dynamic_mesh_index_data::make_shared(6);

    auto device = objc_ptr_with_move_object(MTLCreateSystemDefaultDevice());
    if (!device) {
        std::cout << "skip : " << __PRETTY_FUNCTION__ << std::endl;
        return;
    }

    auto metal_system = metal_system::make_shared(device.object(), nil);

    XCTAssertNil(vertex_data->mtlBuffer());
    XCTAssertNil(index_data->mtlBuffer());

    auto vertex_setup_result = vertex_data->metal_setup(metal_system);
    XCTAssertTrue(vertex_setup_result);

    if (!vertex_setup_result) {
        std::cout << "setup_error::" << to_string(vertex_setup_result.error()) << std::endl;
    }

    auto index_setup_result = index_data->metal_setup(metal_system);
    XCTAssertTrue(index_setup_result);

    if (!index_setup_result) {
        std::cout << "setup_error::" << to_string(index_setup_result.error()) << std::endl;
    }

    XCTAssertNotNil(vertex_data->mtlBuffer());
    XCTAssertNotNil(index_data->mtlBuffer());
    XCTAssertEqual(vertex_data->mtlBuffer().length, 4 * sizeof(vertex2d_t) * 2);
    XCTAssertEqual(index_data->mtlBuffer().length, 6 * sizeof(index2d_t) * 2);
}

- (void)test_write_to_buffer_dynamic {
    auto const vertex_data = dynamic_mesh_vertex_data::make_shared(4);
    auto const index_data = dynamic_mesh_index_data::make_shared(6);

    auto device = objc_ptr_with_move_object(MTLCreateSystemDefaultDevice());
    if (!device) {
        std::cout << "skip : " << __PRETTY_FUNCTION__ << std::endl;
        return;
    }

    auto metal_system = metal_system::make_shared(device.object(), nil);

    auto const renderable_vertex = vertex_data;
    auto const renderable_index = index_data;

    XCTAssertTrue(vertex_data->metal_setup(metal_system));
    XCTAssertTrue(index_data->metal_setup(metal_system));

    vertex2d_t *vertex_head_ptr = static_cast<vertex2d_t *>([renderable_vertex->mtlBuffer() contents]);
    index2d_t *index_head_ptr = static_cast<index2d_t *>([renderable_index->mtlBuffer() contents]);

    vertex_data->write([](std::vector<vertex2d_t> &vertices) {
        for (auto const &idx : make_each_index(4)) {
            float const value = idx;
            vertices[idx].position.x = value;
            vertices[idx].position.y = value + 100.0f;
            vertices[idx].tex_coord.x = value + 200.0f;
            vertices[idx].tex_coord.y = value + 300.0f;
        }
    });

    index_data->write([](std::vector<index2d_t> &indices) {
        for (auto const &idx : make_each_index(6)) {
            indices[idx] = idx + 400;
        }
    });

    XCTAssertEqual(renderable_vertex->byte_offset(), 0);
    XCTAssertEqual(renderable_index->byte_offset(), 0);

    renderable_vertex->update_render_buffer();
    renderable_index->update_render_buffer();

    XCTAssertEqual(renderable_vertex->byte_offset(), sizeof(vertex2d_t) * 4);
    XCTAssertEqual(renderable_index->byte_offset(), sizeof(index2d_t) * 6);

    auto vertex_ptr = &vertex_head_ptr[renderable_vertex->byte_offset() / sizeof(vertex2d_t)];
    auto index_ptr = &index_head_ptr[renderable_index->byte_offset() / sizeof(index2d_t)];

    for (auto const &idx : make_each_index(4)) {
        float const value = idx;
        XCTAssertEqual(vertex_ptr[idx].position.x, value);
        XCTAssertEqual(vertex_ptr[idx].position.y, value + 100.0f);
        XCTAssertEqual(vertex_ptr[idx].tex_coord.x, value + 200.0f);
        XCTAssertEqual(vertex_ptr[idx].tex_coord.y, value + 300.0f);
    }

    for (auto const &idx : make_each_index(6)) {
        XCTAssertEqual(index_ptr[idx], idx + 400);
    }

    vertex_data->write([](std::vector<vertex2d_t> &vertices) {
        for (auto const &idx : make_each_index(4)) {
            float const value = idx;
            vertices[idx].position.x = value + 1000.0f;
            vertices[idx].position.y = value + 1100.0f;
            vertices[idx].tex_coord.x = value + 1200.0f;
            vertices[idx].tex_coord.y = value + 1300.0f;
        }
    });

    index_data->write([](std::vector<index2d_t> &indices) {
        for (auto const &idx : make_each_index(6)) {
            indices[idx] = idx + 1400;
        }
    });

    renderable_vertex->update_render_buffer();
    renderable_index->update_render_buffer();

    XCTAssertEqual(renderable_vertex->byte_offset(), 0);
    XCTAssertEqual(renderable_index->byte_offset(), 0);

    vertex_ptr = vertex_head_ptr;
    index_ptr = index_head_ptr;

    for (auto const &idx : make_each_index(4)) {
        float const value = idx;
        XCTAssertEqual(vertex_ptr[idx].position.x, value + 1000.0f);
        XCTAssertEqual(vertex_ptr[idx].position.y, value + 1100.0f);
        XCTAssertEqual(vertex_ptr[idx].tex_coord.x, value + 1200.0f);
        XCTAssertEqual(vertex_ptr[idx].tex_coord.y, value + 1300.0f);
    }

    for (auto const &idx : make_each_index(6)) {
        XCTAssertEqual(index_ptr[idx], idx + 1400);
    }

    renderable_vertex->update_render_buffer();
    renderable_index->update_render_buffer();

    XCTAssertEqual(renderable_vertex->byte_offset(), 0);
    XCTAssertEqual(renderable_index->byte_offset(), 0);

    vertex_data->write([](std::vector<vertex2d_t> &vertices) {});
    index_data->write([](std::vector<index2d_t> &indices) {});

    renderable_vertex->update_render_buffer();
    renderable_index->update_render_buffer();

    XCTAssertEqual(renderable_vertex->byte_offset(), sizeof(vertex2d_t) * 4);
    XCTAssertEqual(renderable_index->byte_offset(), sizeof(index2d_t) * 6);
}

- (void)test_clear_updates {
    auto const mesh_vertex_data = static_mesh_vertex_data::make_shared(1);
    auto const mesh_index_data = static_mesh_index_data::make_shared(1);
    auto const mesh = mesh::make_shared({}, mesh_vertex_data, mesh_index_data, nullptr);

    XCTAssertTrue(renderable_mesh::cast(mesh)->updates().flags.any());
    XCTAssertTrue(mesh_vertex_data->updates().flags.any());
    XCTAssertTrue(mesh_index_data->updates().flags.any());

    renderable_mesh::cast(mesh)->clear_updates();

    XCTAssertFalse(renderable_mesh::cast(mesh)->updates().flags.any());
    XCTAssertFalse(mesh_vertex_data->updates().flags.any());
    XCTAssertFalse(mesh_index_data->updates().flags.any());
}

- (void)test_updates {
    auto const mesh_vertex_data = static_mesh_vertex_data::make_shared(1);
    auto const mesh_index_data = static_mesh_index_data::make_shared(1);
    auto const mesh = mesh::make_shared({}, mesh_vertex_data, mesh_index_data, nullptr);

    renderable_mesh::cast(mesh)->clear_updates();
    mesh->set_use_mesh_color(true);

    XCTAssertEqual(renderable_mesh::cast(mesh)->updates().flags.count(), 1);
    XCTAssertTrue(renderable_mesh::cast(mesh)->updates().test(mesh_update_reason::use_mesh_color));
}

- (void)test_is_rendering_color_exists {
    auto mesh = mesh::make_shared({.use_mesh_color = false, .color = {.v = 1.0f}}, nullptr, nullptr, nullptr);

    XCTAssertFalse(renderable_mesh::cast(mesh)->is_rendering_color_exists());

    auto const mesh_vertex_data = static_mesh_vertex_data::make_shared(1);
    auto const mesh_index_data = static_mesh_index_data::make_shared(1);
    mesh->set_vertex_data(mesh_vertex_data);
    mesh->set_index_data(mesh_index_data);

    XCTAssertTrue(renderable_mesh::cast(mesh)->is_rendering_color_exists());

    mesh->set_use_mesh_color(false);
    mesh->set_color({.v = 0.0f});

    XCTAssertTrue(renderable_mesh::cast(mesh)->is_rendering_color_exists());

    mesh->set_use_mesh_color(true);
    mesh->set_color({.v = 0.0f});

    XCTAssertTrue(renderable_mesh::cast(mesh)->is_rendering_color_exists());

    auto const empty_mesh_vertex_data = static_mesh_vertex_data::make_shared(0);
    auto const empty_mesh_index_data = static_mesh_index_data::make_shared(0);
    mesh->set_vertex_data(empty_mesh_vertex_data);
    mesh->set_index_data(empty_mesh_index_data);

    XCTAssertFalse(renderable_mesh::cast(mesh)->is_rendering_color_exists());
}

- (void)test_metal_setup {
    auto device = objc_ptr_with_move_object(MTLCreateSystemDefaultDevice());
    if (!device) {
        std::cout << "skip : " << __PRETTY_FUNCTION__ << std::endl;
        return;
    }

    auto metal_system = metal_system::make_shared(device.object(), nil);

    auto const mesh_vertex_data = static_mesh_vertex_data::make_shared(1);
    auto const mesh_index_data = static_mesh_index_data::make_shared(1);
    auto mesh = mesh::make_shared({}, mesh_vertex_data, mesh_index_data, nullptr);

    XCTAssertTrue(mesh->metal_setup(metal_system));
}

- (void)test_mesh_update_reason_to_string {
    XCTAssertEqual(to_string(mesh_update_reason::vertex_data), "vertex_data");
    XCTAssertEqual(to_string(mesh_update_reason::index_data), "index_data");
    XCTAssertEqual(to_string(mesh_update_reason::texture), "texture");
    XCTAssertEqual(to_string(mesh_update_reason::primitive_type), "primitive_type");
    XCTAssertEqual(to_string(mesh_update_reason::color), "color");
    XCTAssertEqual(to_string(mesh_update_reason::use_mesh_color), "use_mesh_color");
    XCTAssertEqual(to_string(mesh_update_reason::matrix), "matrix");
    XCTAssertEqual(to_string(mesh_update_reason::count), "count");
}

- (void)test_mesh_update_reason_ostream {
    auto const reasons = {mesh_update_reason::vertex_data, mesh_update_reason::index_data,
                          mesh_update_reason::texture,     mesh_update_reason::primitive_type,
                          mesh_update_reason::color,       mesh_update_reason::use_mesh_color,
                          mesh_update_reason::count};

    for (auto const &reason : reasons) {
        std::ostringstream stream;
        stream << reason;
        XCTAssertEqual(stream.str(), to_string(reason));
    }
}

@end
