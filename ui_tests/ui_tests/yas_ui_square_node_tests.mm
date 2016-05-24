//
//  yas_ui_square_node_tests.mm
//

#import <XCTest/XCTest.h>
#import "yas_ui_mesh_data.h"
#import "yas_ui_square_node.h"

using namespace yas;

@interface yas_ui_square_node_tests : XCTestCase

@end

@implementation yas_ui_square_node_tests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)test_create {
    auto square_node = ui::make_square_node(2);

    XCTAssertTrue(square_node);
    XCTAssertTrue(square_node.square_mesh_data().dynamic_mesh_data());

    XCTAssertEqual(square_node.square_mesh_data().dynamic_mesh_data().vertex_count(), 2 * 4);
    XCTAssertEqual(square_node.square_mesh_data().dynamic_mesh_data().index_count(), 2 * 6);

    auto const indices = square_node.square_mesh_data().dynamic_mesh_data().indices();

    XCTAssertEqual(indices[0], 0);
    XCTAssertEqual(indices[1], 2);
    XCTAssertEqual(indices[2], 1);
    XCTAssertEqual(indices[3], 1);
    XCTAssertEqual(indices[4], 2);
    XCTAssertEqual(indices[5], 3);

    XCTAssertEqual(indices[6], 4);
    XCTAssertEqual(indices[7], 6);
    XCTAssertEqual(indices[8], 5);
    XCTAssertEqual(indices[9], 5);
    XCTAssertEqual(indices[10], 6);
    XCTAssertEqual(indices[11], 7);
}

- (void)test_create_null {
    ui::square_node square_node{nullptr};

    XCTAssertFalse(square_node);
}

- (void)test_set_index {
    auto square_node = ui::make_square_node(2);

    auto const indices = square_node.square_mesh_data().dynamic_mesh_data().indices();

    square_node.square_mesh_data().set_square_index(0, 1);

    XCTAssertEqual(indices[0], 4);
    XCTAssertEqual(indices[1], 6);
    XCTAssertEqual(indices[2], 5);
    XCTAssertEqual(indices[3], 5);
    XCTAssertEqual(indices[4], 6);
    XCTAssertEqual(indices[5], 7);

    square_node.square_mesh_data().set_square_index(1, 0);

    XCTAssertEqual(indices[6], 0);
    XCTAssertEqual(indices[7], 2);
    XCTAssertEqual(indices[8], 1);
    XCTAssertEqual(indices[9], 1);
    XCTAssertEqual(indices[10], 2);
    XCTAssertEqual(indices[11], 3);
}

- (void)test_set_indices {
    auto square_node = ui::make_square_node(2);
    auto const indices = square_node.square_mesh_data().dynamic_mesh_data().indices();

    square_node.square_mesh_data().set_square_indices({{0, 1}, {1, 0}});

    XCTAssertEqual(indices[0], 4);
    XCTAssertEqual(indices[1], 6);
    XCTAssertEqual(indices[2], 5);
    XCTAssertEqual(indices[3], 5);
    XCTAssertEqual(indices[4], 6);
    XCTAssertEqual(indices[5], 7);

    XCTAssertEqual(indices[6], 0);
    XCTAssertEqual(indices[7], 2);
    XCTAssertEqual(indices[8], 1);
    XCTAssertEqual(indices[9], 1);
    XCTAssertEqual(indices[10], 2);
    XCTAssertEqual(indices[11], 3);
}

- (void)test_set_vertex_by_region {
    auto square_node = ui::make_square_node(2);
    auto vertices = square_node.square_mesh_data().dynamic_mesh_data().vertices();

    square_node.square_mesh_data().set_square_position({1.0f, 2.0f, 3.0f, 4.0f}, 0);

    XCTAssertEqual(vertices[0].position.x, 1.0f);
    XCTAssertEqual(vertices[0].position.y, 2.0f);
    XCTAssertEqual(vertices[1].position.x, 4.0f);
    XCTAssertEqual(vertices[1].position.y, 2.0f);
    XCTAssertEqual(vertices[2].position.x, 1.0f);
    XCTAssertEqual(vertices[2].position.y, 6.0f);
    XCTAssertEqual(vertices[3].position.x, 4.0f);
    XCTAssertEqual(vertices[3].position.y, 6.0f);

    square_node.square_mesh_data().set_square_position({2.0f, 3.0f, 4.0f, 5.0f}, 1);

    XCTAssertEqual(vertices[4].position.x, 2.0f);
    XCTAssertEqual(vertices[4].position.y, 3.0f);
    XCTAssertEqual(vertices[5].position.x, 6.0f);
    XCTAssertEqual(vertices[5].position.y, 3.0f);
    XCTAssertEqual(vertices[6].position.x, 2.0f);
    XCTAssertEqual(vertices[6].position.y, 8.0f);
    XCTAssertEqual(vertices[7].position.x, 6.0f);
    XCTAssertEqual(vertices[7].position.y, 8.0f);
}

- (void)test_set_tex_coords {
    auto square_node = ui::make_square_node(2);
    auto vertices = square_node.square_mesh_data().dynamic_mesh_data().vertices();

    square_node.square_mesh_data().set_square_tex_coords(ui::uint_region{10, 20, 30, 40}, 0);

    XCTAssertEqual(vertices[0].tex_coord.x, 10.0f);
    XCTAssertEqual(vertices[0].tex_coord.y, 60.0f);
    XCTAssertEqual(vertices[1].tex_coord.x, 40.0f);
    XCTAssertEqual(vertices[1].tex_coord.y, 60.0f);
    XCTAssertEqual(vertices[2].tex_coord.x, 10.0f);
    XCTAssertEqual(vertices[2].tex_coord.y, 20.0f);
    XCTAssertEqual(vertices[3].tex_coord.x, 40.0f);
    XCTAssertEqual(vertices[3].tex_coord.y, 20.0f);

    square_node.square_mesh_data().set_square_tex_coords(ui::uint_region{100, 200, 300, 400}, 0);

    XCTAssertEqual(vertices[0].tex_coord.x, 100.0f);
    XCTAssertEqual(vertices[0].tex_coord.y, 600.0f);
    XCTAssertEqual(vertices[1].tex_coord.x, 400.0f);
    XCTAssertEqual(vertices[1].tex_coord.y, 600.0f);
    XCTAssertEqual(vertices[2].tex_coord.x, 100.0f);
    XCTAssertEqual(vertices[2].tex_coord.y, 200.0f);
    XCTAssertEqual(vertices[3].tex_coord.x, 400.0f);
    XCTAssertEqual(vertices[3].tex_coord.y, 200.0f);
}

- (void)test_set_vertex_by_data {
    auto square_node = ui::make_square_node(2);
    auto vertices = square_node.square_mesh_data().dynamic_mesh_data().vertices();

    ui::vertex2d_t in_data[4];

    in_data[0].position.x = 1.0f;
    in_data[0].position.y = 2.0f;
    in_data[1].position.x = 3.0f;
    in_data[1].position.y = 4.0f;
    in_data[2].position.x = 5.0f;
    in_data[2].position.y = 6.0f;
    in_data[3].position.x = 7.0f;
    in_data[3].position.y = 8.0f;

    in_data[0].tex_coord.x = 11.0f;
    in_data[0].tex_coord.y = 12.0f;
    in_data[1].tex_coord.x = 13.0f;
    in_data[1].tex_coord.y = 14.0f;
    in_data[2].tex_coord.x = 15.0f;
    in_data[2].tex_coord.y = 16.0f;
    in_data[3].tex_coord.x = 17.0f;
    in_data[3].tex_coord.y = 18.0f;

    square_node.square_mesh_data().set_square_vertex(in_data, 0);

    XCTAssertEqual(vertices[0].position.x, 1.0f);
    XCTAssertEqual(vertices[0].position.y, 2.0f);
    XCTAssertEqual(vertices[1].position.x, 3.0f);
    XCTAssertEqual(vertices[1].position.y, 4.0f);
    XCTAssertEqual(vertices[2].position.x, 5.0f);
    XCTAssertEqual(vertices[2].position.y, 6.0f);
    XCTAssertEqual(vertices[3].position.x, 7.0f);
    XCTAssertEqual(vertices[3].position.y, 8.0f);

    XCTAssertEqual(vertices[0].tex_coord.x, 11.0f);
    XCTAssertEqual(vertices[0].tex_coord.y, 12.0f);
    XCTAssertEqual(vertices[1].tex_coord.x, 13.0f);
    XCTAssertEqual(vertices[1].tex_coord.y, 14.0f);
    XCTAssertEqual(vertices[2].tex_coord.x, 15.0f);
    XCTAssertEqual(vertices[2].tex_coord.y, 16.0f);
    XCTAssertEqual(vertices[3].tex_coord.x, 17.0f);
    XCTAssertEqual(vertices[3].tex_coord.y, 18.0f);

    in_data[0].position.x = 101.0f;
    in_data[0].position.y = 102.0f;
    in_data[1].position.x = 103.0f;
    in_data[1].position.y = 104.0f;
    in_data[2].position.x = 105.0f;
    in_data[2].position.y = 106.0f;
    in_data[3].position.x = 107.0f;
    in_data[3].position.y = 108.0f;

    in_data[0].tex_coord.x = 111.0f;
    in_data[0].tex_coord.y = 112.0f;
    in_data[1].tex_coord.x = 113.0f;
    in_data[1].tex_coord.y = 114.0f;
    in_data[2].tex_coord.x = 115.0f;
    in_data[2].tex_coord.y = 116.0f;
    in_data[3].tex_coord.x = 117.0f;
    in_data[3].tex_coord.y = 118.0f;

    square_node.square_mesh_data().set_square_vertex(in_data, 1);

    XCTAssertEqual(vertices[4].position.x, 101.0f);
    XCTAssertEqual(vertices[4].position.y, 102.0f);
    XCTAssertEqual(vertices[5].position.x, 103.0f);
    XCTAssertEqual(vertices[5].position.y, 104.0f);
    XCTAssertEqual(vertices[6].position.x, 105.0f);
    XCTAssertEqual(vertices[6].position.y, 106.0f);
    XCTAssertEqual(vertices[7].position.x, 107.0f);
    XCTAssertEqual(vertices[7].position.y, 108.0f);

    XCTAssertEqual(vertices[4].tex_coord.x, 111.0f);
    XCTAssertEqual(vertices[4].tex_coord.y, 112.0f);
    XCTAssertEqual(vertices[5].tex_coord.x, 113.0f);
    XCTAssertEqual(vertices[5].tex_coord.y, 114.0f);
    XCTAssertEqual(vertices[6].tex_coord.x, 115.0f);
    XCTAssertEqual(vertices[6].tex_coord.y, 116.0f);
    XCTAssertEqual(vertices[7].tex_coord.x, 117.0f);
    XCTAssertEqual(vertices[7].tex_coord.y, 118.0f);
}

- (void)test_set_square_count {
    auto sq_mesh_data = ui::make_square_mesh_data(4);

    XCTAssertEqual(sq_mesh_data.dynamic_mesh_data().index_count(), 4 * 6);

    sq_mesh_data.set_square_count(2);

    XCTAssertEqual(sq_mesh_data.dynamic_mesh_data().index_count(), 2 * 6);
}

@end
