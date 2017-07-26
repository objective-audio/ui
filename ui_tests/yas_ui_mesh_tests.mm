//
//  yas_ui_mesh_tests.mm
//

#import <XCTest/XCTest.h>
#import <iostream>
#import <sstream>
#import "yas_each_index.h"
#import "yas_objc_ptr.h"
#import "yas_ui.h"

using namespace yas;

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
    ui::mesh mesh;

    XCTAssertFalse(mesh.mesh_data());
    XCTAssertFalse(mesh.texture());
    XCTAssertEqual(mesh.color()[0], 1.0f);
    XCTAssertEqual(mesh.color()[1], 1.0f);
    XCTAssertEqual(mesh.color()[2], 1.0f);
    XCTAssertEqual(mesh.color()[3], 1.0f);
    XCTAssertEqual(mesh.primitive_type(), ui::primitive_type::triangle);
    XCTAssertFalse(mesh.is_use_mesh_color());

    auto matrix = mesh.renderable().matrix();
    auto identity_matrix = matrix_identity_float4x4;
    for (auto const &col : each_index<std::size_t>(4)) {
        for (auto const &row : each_index<std::size_t>(4)) {
            XCTAssertEqual(matrix.columns[col][row], identity_matrix.columns[col][row]);
        }
    }

    XCTAssertTrue(mesh.metal());
    XCTAssertTrue(mesh.renderable());
}

- (void)test_create_null_mesh {
    ui::mesh mesh{nullptr};

    XCTAssertFalse(mesh);
}

- (void)test_set_mesh_variables {
    auto device = make_objc_ptr(MTLCreateSystemDefaultDevice());
    if (!device) {
        std::cout << "skip : " << __PRETTY_FUNCTION__ << std::endl;
        return;
    }

    ui::mesh mesh;
    ui::mesh_data mesh_data{{.vertex_count = 4, .index_count = 6}};

    ui::metal_system metal_system{device.object()};

    auto texture = ui::make_texture({.metal_system = metal_system, .point_size = {16, 8}, .scale_factor = 1.0}).value();

    mesh.set_mesh_data(mesh_data);
    mesh.set_texture(texture);
    mesh.set_color({0.1f, 0.2f, 0.3f, 0.4f});
    mesh.set_primitive_type(ui::primitive_type::point);
    mesh.set_use_mesh_color(true);

    XCTAssertEqual(mesh.texture(), texture);
    XCTAssertEqual(mesh.color()[0], 0.1f);
    XCTAssertEqual(mesh.color()[1], 0.2f);
    XCTAssertEqual(mesh.color()[2], 0.3f);
    XCTAssertEqual(mesh.color()[3], 0.4f);
    XCTAssertEqual(mesh.mesh_data(), mesh_data);
    XCTAssertEqual(mesh.primitive_type(), ui::primitive_type::point);
    XCTAssertTrue(mesh.is_use_mesh_color());
}

- (void)test_mesh_const_variables {
    auto device = make_objc_ptr(MTLCreateSystemDefaultDevice());
    if (!device) {
        std::cout << "skip : " << __PRETTY_FUNCTION__ << std::endl;
        return;
    }

    ui::mesh mesh;
    ui::mesh_data mesh_data{{.vertex_count = 4, .index_count = 6}};

    ui::metal_system metal_system{device.object()};

    auto texture = ui::make_texture({.metal_system = metal_system, .point_size = {16, 8}, .scale_factor = 1.0}).value();

    mesh.set_mesh_data(mesh_data);
    mesh.set_texture(texture);

    ui::mesh const const_mesh = mesh;

    XCTAssertEqual(const_mesh.texture(), texture);
    XCTAssertEqual(const_mesh.mesh_data(), mesh_data);
}

- (void)test_set_renderable_variables {
    ui::mesh mesh;

    auto &renderable = mesh.renderable();

    simd::float4x4 matrix;
    matrix.columns[0] = {1.0f, 2.0f, 3.0f, 4.0f};
    matrix.columns[1] = {5.0f, 6.0f, 7.0f, 8.0f};
    matrix.columns[2] = {9.0f, 10.0f, 11.0f, 12.0f};
    matrix.columns[3] = {13.0f, 14.0f, 15.0f, 16.0f};

    renderable.set_matrix(matrix);

    XCTAssertEqual(renderable.matrix().columns[0][0], 1.0f);
    XCTAssertEqual(renderable.matrix().columns[0][1], 2.0f);
    XCTAssertEqual(renderable.matrix().columns[0][2], 3.0f);
    XCTAssertEqual(renderable.matrix().columns[0][3], 4.0f);

    XCTAssertEqual(renderable.matrix().columns[1][0], 5.0f);
    XCTAssertEqual(renderable.matrix().columns[1][1], 6.0f);
    XCTAssertEqual(renderable.matrix().columns[1][2], 7.0f);
    XCTAssertEqual(renderable.matrix().columns[1][3], 8.0f);

    XCTAssertEqual(renderable.matrix().columns[2][0], 9.0f);
    XCTAssertEqual(renderable.matrix().columns[2][1], 10.0f);
    XCTAssertEqual(renderable.matrix().columns[2][2], 11.0f);
    XCTAssertEqual(renderable.matrix().columns[2][3], 12.0f);

    XCTAssertEqual(renderable.matrix().columns[3][0], 13.0f);
    XCTAssertEqual(renderable.matrix().columns[3][1], 14.0f);
    XCTAssertEqual(renderable.matrix().columns[3][2], 15.0f);
    XCTAssertEqual(renderable.matrix().columns[3][3], 16.0f);
}

- (void)test_mesh_setup_metal_buffer_constant {
    ui::mesh_data mesh_data{{.vertex_count = 4, .index_count = 6}};

    auto device = make_objc_ptr(MTLCreateSystemDefaultDevice());
    if (!device) {
        std::cout << "skip : " << __PRETTY_FUNCTION__ << std::endl;
        return;
    }

    ui::metal_system metal_system{device.object()};

    XCTAssertNil(mesh_data.renderable().vertexBuffer());
    XCTAssertNil(mesh_data.renderable().indexBuffer());

    auto setup_result = mesh_data.metal().metal_setup(metal_system);
    XCTAssertTrue(setup_result);

    if (!setup_result) {
        std::cout << "setup_error::" << to_string(setup_result.error()) << std::endl;
    }

    XCTAssertNotNil(mesh_data.renderable().vertexBuffer());
    XCTAssertNotNil(mesh_data.renderable().indexBuffer());
    XCTAssertEqual(mesh_data.renderable().vertexBuffer().length, 4 * sizeof(ui::vertex2d_t));
    XCTAssertEqual(mesh_data.renderable().indexBuffer().length, 6 * sizeof(ui::index2d_t));
}

- (void)test_mesh_setup_metal_buffer_dynamic {
    ui::dynamic_mesh_data mesh_data{{.vertex_count = 4, .index_count = 6}};

    auto device = make_objc_ptr(MTLCreateSystemDefaultDevice());
    if (!device) {
        std::cout << "skip : " << __PRETTY_FUNCTION__ << std::endl;
        return;
    }

    ui::metal_system metal_system{device.object()};

    XCTAssertNil(mesh_data.renderable().vertexBuffer());
    XCTAssertNil(mesh_data.renderable().indexBuffer());

    auto setup_result = mesh_data.metal().metal_setup(metal_system);
    XCTAssertTrue(setup_result);

    if (!setup_result) {
        std::cout << "setup_error::" << to_string(setup_result.error()) << std::endl;
    }

    XCTAssertNotNil(mesh_data.renderable().vertexBuffer());
    XCTAssertNotNil(mesh_data.renderable().indexBuffer());
    XCTAssertEqual(mesh_data.renderable().vertexBuffer().length, 4 * sizeof(ui::vertex2d_t) * 2);
    XCTAssertEqual(mesh_data.renderable().indexBuffer().length, 6 * sizeof(ui::index2d_t) * 2);
}

- (void)test_write_to_buffer_dynamic {
    ui::dynamic_mesh_data mesh_data{{.vertex_count = 4, .index_count = 6}};

    auto device = make_objc_ptr(MTLCreateSystemDefaultDevice());
    if (!device) {
        std::cout << "skip : " << __PRETTY_FUNCTION__ << std::endl;
        return;
    }

    ui::metal_system metal_system{device.object()};

    auto &renderable = mesh_data.renderable();

    XCTAssertTrue(mesh_data.metal().metal_setup(metal_system));

    ui::vertex2d_t *vertex_top_ptr = static_cast<ui::vertex2d_t *>([renderable.vertexBuffer() contents]);
    ui::index2d_t *index_top_ptr = static_cast<ui::index2d_t *>([renderable.indexBuffer() contents]);

    mesh_data.write([](std::vector<ui::vertex2d_t> &vertices, std::vector<ui::index2d_t> &indices) {
        for (auto const &idx : make_each_index(4)) {
            float const value = idx;
            vertices[idx].position.x = value;
            vertices[idx].position.y = value + 100.0f;
            vertices[idx].tex_coord.x = value + 200.0f;
            vertices[idx].tex_coord.y = value + 300.0f;
        }

        for (auto const &idx : make_each_index(6)) {
            indices[idx] = idx + 400;
        }
    });

    XCTAssertEqual(renderable.vertex_buffer_byte_offset(), 0);
    XCTAssertEqual(renderable.index_buffer_byte_offset(), 0);

    renderable.update_render_buffer();

    XCTAssertEqual(renderable.vertex_buffer_byte_offset(), sizeof(ui::vertex2d_t) * 4);
    XCTAssertEqual(renderable.index_buffer_byte_offset(), sizeof(ui::index2d_t) * 6);

    auto vertex_ptr = &vertex_top_ptr[renderable.vertex_buffer_byte_offset() / sizeof(ui::vertex2d_t)];
    auto index_ptr = &index_top_ptr[renderable.index_buffer_byte_offset() / sizeof(ui::index2d_t)];

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

    mesh_data.write([](std::vector<ui::vertex2d_t> &vertices, std::vector<ui::index2d_t> &indices) {
        for (auto const &idx : make_each_index(4)) {
            float const value = idx;
            vertices[idx].position.x = value + 1000.0f;
            vertices[idx].position.y = value + 1100.0f;
            vertices[idx].tex_coord.x = value + 1200.0f;
            vertices[idx].tex_coord.y = value + 1300.0f;
        }

        for (auto const &idx : make_each_index(6)) {
            indices[idx] = idx + 1400;
        }
    });

    renderable.update_render_buffer();

    XCTAssertEqual(renderable.vertex_buffer_byte_offset(), 0);
    XCTAssertEqual(renderable.index_buffer_byte_offset(), 0);

    vertex_ptr = vertex_top_ptr;
    index_ptr = index_top_ptr;

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

    renderable.update_render_buffer();

    XCTAssertEqual(renderable.vertex_buffer_byte_offset(), 0);
    XCTAssertEqual(renderable.index_buffer_byte_offset(), 0);

    mesh_data.write([](std::vector<ui::vertex2d_t> &vertices, std::vector<ui::index2d_t> &indices) {});

    renderable.update_render_buffer();

    XCTAssertEqual(renderable.vertex_buffer_byte_offset(), sizeof(ui::vertex2d_t) * 4);
    XCTAssertEqual(renderable.index_buffer_byte_offset(), sizeof(ui::index2d_t) * 6);
}

- (void)test_clear_updates {
    ui::mesh mesh;
    ui::mesh_data mesh_data{{.vertex_count = 1, .index_count = 1}};
    mesh.set_mesh_data(mesh_data);

    XCTAssertTrue(mesh.renderable().updates().flags.any());
    XCTAssertTrue(mesh_data.renderable().updates().flags.any());

    mesh.renderable().clear_updates();

    XCTAssertFalse(mesh.renderable().updates().flags.any());
    XCTAssertFalse(mesh_data.renderable().updates().flags.any());
}

- (void)test_updates {
    ui::mesh mesh;
    ui::mesh_data mesh_data{{.vertex_count = 1, .index_count = 1}};
    mesh.set_mesh_data(mesh_data);

    mesh.renderable().clear_updates();
    mesh.set_use_mesh_color(true);

    XCTAssertEqual(mesh.renderable().updates().flags.count(), 1);
    XCTAssertTrue(mesh.renderable().updates().test(ui::mesh_update_reason::use_mesh_color));
}

- (void)test_is_rendering_color_exists {
    ui::mesh mesh;

    mesh.set_use_mesh_color(false);
    mesh.set_color(1.0f);

    XCTAssertFalse(mesh.renderable().is_rendering_color_exists());

    ui::mesh_data mesh_data{{.vertex_count = 1, .index_count = 1}};
    mesh.set_mesh_data(mesh_data);

    XCTAssertTrue(mesh.renderable().is_rendering_color_exists());

    mesh.set_use_mesh_color(false);
    mesh.set_color(0.0f);

    XCTAssertFalse(mesh.renderable().is_rendering_color_exists());

    mesh.set_use_mesh_color(true);
    mesh.set_color(0.0f);

    XCTAssertTrue(mesh.renderable().is_rendering_color_exists());
}

- (void)test_metal_setup {
    auto device = make_objc_ptr(MTLCreateSystemDefaultDevice());
    if (!device) {
        std::cout << "skip : " << __PRETTY_FUNCTION__ << std::endl;
        return;
    }

    ui::metal_system metal_system{device.object()};

    ui::mesh mesh;
    ui::mesh_data mesh_data{{.vertex_count = 1, .index_count = 1}};
    mesh.set_mesh_data(mesh_data);

    XCTAssertTrue(mesh.metal().metal_setup(metal_system));
}

- (void)test_mesh_update_reason_to_string {
    XCTAssertEqual(to_string(ui::mesh_update_reason::mesh_data), "mesh_data");
    XCTAssertEqual(to_string(ui::mesh_update_reason::texture), "texture");
    XCTAssertEqual(to_string(ui::mesh_update_reason::primitive_type), "primitive_type");
    XCTAssertEqual(to_string(ui::mesh_update_reason::color), "color");
    XCTAssertEqual(to_string(ui::mesh_update_reason::use_mesh_color), "use_mesh_color");
    XCTAssertEqual(to_string(ui::mesh_update_reason::matrix), "matrix");
    XCTAssertEqual(to_string(ui::mesh_update_reason::count), "count");
}

- (void)test_mesh_update_reason_ostream {
    auto const reasons = {ui::mesh_update_reason::mesh_data,      ui::mesh_update_reason::texture,
                          ui::mesh_update_reason::primitive_type, ui::mesh_update_reason::color,
                          ui::mesh_update_reason::use_mesh_color, ui::mesh_update_reason::count};

    for (auto const &reason : reasons) {
        std::ostringstream stream;
        stream << reason;
        XCTAssertEqual(stream.str(), to_string(reason));
    }
}

@end
