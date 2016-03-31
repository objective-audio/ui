//
//  yas_ui_mesh_tests.mm
//

#import <XCTest/XCTest.h>
#import "yas_each_index.h"
#import "yas_ui_mesh.h"
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

- (void)test_create {
    ui::mesh mesh{4, 6, false};

    XCTAssertEqual(mesh.vertex_count(), 4);
    XCTAssertEqual(mesh.index_count(), 6);
    XCTAssertFalse(mesh.is_dynamic());
    XCTAssertFalse(mesh.texture());
    XCTAssertEqual(mesh.color()[0], 1.0f);
    XCTAssertEqual(mesh.color()[1], 1.0f);
    XCTAssertEqual(mesh.color()[2], 1.0f);
    XCTAssertEqual(mesh.color()[3], 1.0f);

    auto matrix = mesh.renderable().matrix();
    auto identity_matrix = matrix_identity_float4x4;
    for (auto const &col : each_index<std::size_t>(4)) {
        for (auto const &row : each_index<std::size_t>(4)) {
            XCTAssertEqual(matrix.columns[col][row], identity_matrix.columns[col][row]);
        }
    }

    XCTAssertTrue(mesh.renderable());
}

- (void)test_create_null {
    ui::mesh mesh{nullptr};

    XCTAssertFalse(mesh);
}

- (void)test_write {
    ui::mesh mesh{4, 6, false};

    mesh.write([self](auto &vertices, auto &indices) {
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

    XCTAssertEqual(mesh.vertices()[0].position.x, 0.0f);
    XCTAssertEqual(mesh.vertices()[0].position.y, 1.0f);
    XCTAssertEqual(mesh.vertices()[1].position.x, 2.0f);
    XCTAssertEqual(mesh.vertices()[1].position.y, 3.0f);
    XCTAssertEqual(mesh.vertices()[2].position.x, 4.0f);
    XCTAssertEqual(mesh.vertices()[2].position.y, 5.0f);
    XCTAssertEqual(mesh.vertices()[3].position.x, 6.0f);
    XCTAssertEqual(mesh.vertices()[3].position.y, 7.0f);

    XCTAssertEqual(mesh.indices()[0], 20.0f);
    XCTAssertEqual(mesh.indices()[1], 21.0f);
    XCTAssertEqual(mesh.indices()[2], 22.0f);
    XCTAssertEqual(mesh.indices()[3], 23.0f);
    XCTAssertEqual(mesh.indices()[4], 24.0f);
    XCTAssertEqual(mesh.indices()[5], 25.0f);
}

- (void)test_set_variables_constant {
    ui::mesh mesh{4, 6, false};
    ui::texture texture{{16, 8}, 1.0};

    mesh.set_texture(texture);
    mesh.set_color({0.1f, 0.2f, 0.3f, 0.4f});
    XCTAssertThrows(mesh.set_vertex_count(1));
    XCTAssertThrows(mesh.set_index_count(1));

    XCTAssertEqual(mesh.texture(), texture);
    XCTAssertEqual(mesh.color()[0], 0.1f);
    XCTAssertEqual(mesh.color()[1], 0.2f);
    XCTAssertEqual(mesh.color()[2], 0.3f);
    XCTAssertEqual(mesh.color()[3], 0.4f);
    XCTAssertEqual(mesh.vertex_count(), 4);
    XCTAssertEqual(mesh.index_count(), 6);
}

- (void)test_set_variables_dynamic {
    ui::mesh mesh{4, 6, true};

    XCTAssertEqual(mesh.vertex_count(), 4);
    XCTAssertEqual(mesh.index_count(), 6);

    mesh.set_vertex_count(0);
    mesh.set_index_count(0);

    XCTAssertEqual(mesh.vertex_count(), 0);
    XCTAssertEqual(mesh.index_count(), 0);

    mesh.set_vertex_count(4);
    mesh.set_index_count(6);

    XCTAssertEqual(mesh.vertex_count(), 4);
    XCTAssertEqual(mesh.index_count(), 6);

    XCTAssertThrows(mesh.set_vertex_count(5));
    XCTAssertThrows(mesh.set_index_count(7));
}

- (void)test_set_renderable_variables {
    ui::mesh mesh{0, 0, false};

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

@end
