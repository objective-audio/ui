//
//  yas_ui_mesh_tests.mm
//

#import <XCTest/XCTest.h>
#import "yas_each_index.h"
#import "yas_objc_ptr.h"
#import "yas_ui_mesh.h"
#import "yas_ui_mesh_data.h"
#import "yas_ui_texture.h"

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

- (void)test_create_mesh_data {
    ui::mesh_data mesh_data{4, 6};

    XCTAssertEqual(mesh_data.vertex_count(), 4);
    XCTAssertEqual(mesh_data.index_count(), 6);

    XCTAssertTrue(mesh_data.metal());
    XCTAssertTrue(mesh_data.renderable());
}

- (void)test_create_null_mesh_data {
    ui::mesh_data mesh_data{nullptr};

    XCTAssertFalse(mesh_data);
}

- (void)test_create_mesh {
    ui::mesh mesh;

    XCTAssertFalse(mesh.texture());
    XCTAssertEqual(mesh.color()[0], 1.0f);
    XCTAssertEqual(mesh.color()[1], 1.0f);
    XCTAssertEqual(mesh.color()[2], 1.0f);
    XCTAssertEqual(mesh.color()[3], 1.0f);
    XCTAssertEqual(mesh.primitive_type(), ui::primitive_type::triangle);

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

- (void)test_write_mesh_data {
    ui::mesh_data mesh_data{4, 6};

    mesh_data.write([self](auto &vertices, auto &indices) {
        XCTAssertEqual(vertices.size(), 4);
        XCTAssertEqual(indices.size(), 6);

        vertices[0].position.x = 0.0f;
        vertices[0].position.y = 1.0f;
        vertices[1].position.x = 2.0f;
        vertices[1].position.y = 3.0f;
        vertices[2].position.x = 4.0f;
        vertices[2].position.y = 5.0f;
        vertices[3].position.x = 6.0f;
        vertices[3].position.y = 7.0f;

        vertices[0].tex_coord.x = 10.0f;
        vertices[0].tex_coord.y = 11.0f;
        vertices[1].tex_coord.x = 12.0f;
        vertices[1].tex_coord.y = 13.0f;
        vertices[2].tex_coord.x = 14.0f;
        vertices[2].tex_coord.y = 15.0f;
        vertices[3].tex_coord.x = 16.0f;
        vertices[3].tex_coord.y = 17.0f;

        indices[0] = 20.0f;
        indices[1] = 21.0f;
        indices[2] = 22.0f;
        indices[3] = 23.0f;
        indices[4] = 24.0f;
        indices[5] = 25.0f;
    });

    XCTAssertEqual(mesh_data.vertices()[0].position.x, 0.0f);
    XCTAssertEqual(mesh_data.vertices()[0].position.y, 1.0f);
    XCTAssertEqual(mesh_data.vertices()[1].position.x, 2.0f);
    XCTAssertEqual(mesh_data.vertices()[1].position.y, 3.0f);
    XCTAssertEqual(mesh_data.vertices()[2].position.x, 4.0f);
    XCTAssertEqual(mesh_data.vertices()[2].position.y, 5.0f);
    XCTAssertEqual(mesh_data.vertices()[3].position.x, 6.0f);
    XCTAssertEqual(mesh_data.vertices()[3].position.y, 7.0f);

    XCTAssertEqual(mesh_data.indices()[0], 20.0f);
    XCTAssertEqual(mesh_data.indices()[1], 21.0f);
    XCTAssertEqual(mesh_data.indices()[2], 22.0f);
    XCTAssertEqual(mesh_data.indices()[3], 23.0f);
    XCTAssertEqual(mesh_data.indices()[4], 24.0f);
    XCTAssertEqual(mesh_data.indices()[5], 25.0f);
}

- (void)test_set_variables_dynamic_mesh_data {
    ui::dynamic_mesh_data mesh_data{4, 6};

    XCTAssertEqual(mesh_data.vertex_count(), 4);
    XCTAssertEqual(mesh_data.index_count(), 6);

    mesh_data.set_vertex_count(0);
    mesh_data.set_index_count(0);

    XCTAssertEqual(mesh_data.vertex_count(), 0);
    XCTAssertEqual(mesh_data.index_count(), 0);

    mesh_data.set_vertex_count(4);
    mesh_data.set_index_count(6);

    XCTAssertEqual(mesh_data.vertex_count(), 4);
    XCTAssertEqual(mesh_data.index_count(), 6);

    XCTAssertThrows(mesh_data.set_vertex_count(5));
    XCTAssertThrows(mesh_data.set_index_count(7));
}

- (void)test_set_mesh_variables {
    ui::mesh mesh;
    ui::mesh_data mesh_data{4, 6};
    ui::texture texture{{16, 8}, 1.0};

    mesh.set_data(mesh_data);
    mesh.set_texture(texture);
    mesh.set_color({0.1f, 0.2f, 0.3f, 0.4f});
    mesh.set_primitive_type(ui::primitive_type::point);

    XCTAssertEqual(mesh.texture(), texture);
    XCTAssertEqual(mesh.color()[0], 0.1f);
    XCTAssertEqual(mesh.color()[1], 0.2f);
    XCTAssertEqual(mesh.color()[2], 0.3f);
    XCTAssertEqual(mesh.color()[3], 0.4f);
    XCTAssertEqual(mesh.data(), mesh_data);
    XCTAssertEqual(mesh.primitive_type(), ui::primitive_type::point);
}

- (void)test_set_renderable_variables {
    ui::mesh mesh;

    auto renderable = mesh.renderable();

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
    ui::mesh_data mesh_data{4, 6};

    auto device = make_objc_ptr(MTLCreateSystemDefaultDevice());
    if (!device) {
        std::cout << "skip : " << __PRETTY_FUNCTION__ << std::endl;
        return;
    }

    XCTAssertNil(mesh_data.renderable().vertexBuffer());
    XCTAssertNil(mesh_data.renderable().indexBuffer());

    auto setup_result = mesh_data.metal().setup(device.object());
    XCTAssertTrue(setup_result);

    if (!setup_result) {
        std::cout << "setup_error::" << to_string(setup_result.error()) << std::endl;
    }

    XCTAssertNotNil(mesh_data.renderable().vertexBuffer());
    XCTAssertNotNil(mesh_data.renderable().indexBuffer());
    XCTAssertEqual(mesh_data.renderable().vertexBuffer().length, 4 * sizeof(ui::vertex2d_t));
    XCTAssertEqual(mesh_data.renderable().indexBuffer().length, 6 * sizeof(UInt16));
}

- (void)test_mesh_setup_metal_buffer_dynamic {
    ui::dynamic_mesh_data mesh_data{4, 6};

    auto device = make_objc_ptr(MTLCreateSystemDefaultDevice());
    if (!device) {
        std::cout << "skip : " << __PRETTY_FUNCTION__ << std::endl;
        return;
    }

    XCTAssertNil(mesh_data.renderable().vertexBuffer());
    XCTAssertNil(mesh_data.renderable().indexBuffer());

    auto setup_result = mesh_data.metal().setup(device.object());
    XCTAssertTrue(setup_result);

    if (!setup_result) {
        std::cout << "setup_error::" << to_string(setup_result.error()) << std::endl;
    }

    XCTAssertNotNil(mesh_data.renderable().vertexBuffer());
    XCTAssertNotNil(mesh_data.renderable().indexBuffer());
    XCTAssertEqual(mesh_data.renderable().vertexBuffer().length, 4 * sizeof(ui::vertex2d_t) * 2);
    XCTAssertEqual(mesh_data.renderable().indexBuffer().length, 6 * sizeof(UInt16) * 2);
}

- (void)test_write_to_buffer_dynamic {
    ui::dynamic_mesh_data mesh_data{4, 6};

    auto device = make_objc_ptr(MTLCreateSystemDefaultDevice());
    if (!device) {
        std::cout << "skip : " << __PRETTY_FUNCTION__ << std::endl;
        return;
    }

    auto renderable = mesh_data.renderable();

    XCTAssertTrue(mesh_data.metal().setup(device.object()));

    ui::vertex2d_t *vertex_top_ptr = static_cast<ui::vertex2d_t *>([renderable.vertexBuffer() contents]);
    UInt16 *index_top_ptr = static_cast<UInt16 *>([renderable.indexBuffer() contents]);

    mesh_data.write([](std::vector<ui::vertex2d_t> &vertices, std::vector<UInt16> &indices) {
        for (auto const &idx : make_each(4)) {
            float const value = idx;
            vertices[idx].position.x = value;
            vertices[idx].position.y = value + 100.0f;
            vertices[idx].tex_coord.x = value + 200.0f;
            vertices[idx].tex_coord.y = value + 300.0f;
        }

        for (auto const &idx : make_each(6)) {
            indices[idx] = idx + 400;
        }
    });

    XCTAssertEqual(renderable.vertex_buffer_offset(), 0);
    XCTAssertEqual(renderable.index_buffer_offset(), 0);

    renderable.update_render_buffer_if_needed();

    XCTAssertEqual(renderable.vertex_buffer_offset(), sizeof(ui::vertex2d_t) * 4);
    XCTAssertEqual(renderable.index_buffer_offset(), sizeof(UInt16) * 6);

    auto vertex_ptr = &vertex_top_ptr[renderable.vertex_buffer_offset() / sizeof(ui::vertex2d_t)];
    auto index_ptr = &index_top_ptr[renderable.index_buffer_offset() / sizeof(UInt16)];

    for (auto const &idx : make_each(4)) {
        float const value = idx;
        XCTAssertEqual(vertex_ptr[idx].position.x, value);
        XCTAssertEqual(vertex_ptr[idx].position.y, value + 100.0f);
        XCTAssertEqual(vertex_ptr[idx].tex_coord.x, value + 200.0f);
        XCTAssertEqual(vertex_ptr[idx].tex_coord.y, value + 300.0f);
    }

    for (auto const &idx : make_each(6)) {
        XCTAssertEqual(index_ptr[idx], idx + 400);
    }

    mesh_data.write([](std::vector<ui::vertex2d_t> &vertices, std::vector<UInt16> &indices) {
        for (auto const &idx : make_each(4)) {
            float const value = idx;
            vertices[idx].position.x = value + 1000.0f;
            vertices[idx].position.y = value + 1100.0f;
            vertices[idx].tex_coord.x = value + 1200.0f;
            vertices[idx].tex_coord.y = value + 1300.0f;
        }

        for (auto const &idx : make_each(6)) {
            indices[idx] = idx + 1400;
        }
    });

    renderable.update_render_buffer_if_needed();

    XCTAssertEqual(renderable.vertex_buffer_offset(), 0);
    XCTAssertEqual(renderable.index_buffer_offset(), 0);

    vertex_ptr = vertex_top_ptr;
    index_ptr = index_top_ptr;

    for (auto const &idx : make_each(4)) {
        float const value = idx;
        XCTAssertEqual(vertex_ptr[idx].position.x, value + 1000.0f);
        XCTAssertEqual(vertex_ptr[idx].position.y, value + 1100.0f);
        XCTAssertEqual(vertex_ptr[idx].tex_coord.x, value + 1200.0f);
        XCTAssertEqual(vertex_ptr[idx].tex_coord.y, value + 1300.0f);
    }

    for (auto const &idx : make_each(6)) {
        XCTAssertEqual(index_ptr[idx], idx + 1400);
    }

    renderable.update_render_buffer_if_needed();

    XCTAssertEqual(renderable.vertex_buffer_offset(), 0);
    XCTAssertEqual(renderable.index_buffer_offset(), 0);

    mesh_data.write([](std::vector<ui::vertex2d_t> &vertices, std::vector<UInt16> &indices) {});

    renderable.update_render_buffer_if_needed();

    XCTAssertEqual(renderable.vertex_buffer_offset(), sizeof(ui::vertex2d_t) * 4);
    XCTAssertEqual(renderable.index_buffer_offset(), sizeof(UInt16) * 6);
}

@end
