//
//  yas_ui_square_node_tests.mm
//

#import <XCTest/XCTest.h>
#import "yas_each_index.h"
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

- (void)test_set_square_color {
    auto sq_mesh_data = ui::make_square_mesh_data(1);
    auto vertices = sq_mesh_data.dynamic_mesh_data().vertices();

    sq_mesh_data.set_square_color({0.1f, 0.2f, 0.3f, 0.4f}, 0);

    for (auto const &idx : make_each(4)) {
        auto &color = vertices[idx].color;
        XCTAssertEqual(color[0], 0.1f);
        XCTAssertEqual(color[1], 0.2f);
        XCTAssertEqual(color[2], 0.3f);
        XCTAssertEqual(color[3], 0.4f);
    }

    sq_mesh_data.set_square_color({0.5f, 0.6f, 0.7f, 0.8f}, 0);

    for (auto const &idx : make_each(4)) {
        auto &color = vertices[idx].color;
        XCTAssertEqual(color[0], 0.5f);
        XCTAssertEqual(color[1], 0.6f);
        XCTAssertEqual(color[2], 0.7f);
        XCTAssertEqual(color[3], 0.8f);
    }
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

    in_data[0].color[0] = 21.0f;
    in_data[0].color[1] = 22.0f;
    in_data[0].color[2] = 23.0f;
    in_data[0].color[3] = 24.0f;
    in_data[1].color[0] = 25.0f;
    in_data[1].color[1] = 26.0f;
    in_data[1].color[2] = 27.0f;
    in_data[1].color[3] = 28.0f;
    in_data[2].color[0] = 29.0f;
    in_data[2].color[1] = 30.0f;
    in_data[2].color[2] = 31.0f;
    in_data[2].color[3] = 32.0f;
    in_data[3].color[0] = 33.0f;
    in_data[3].color[1] = 34.0f;
    in_data[3].color[2] = 35.0f;
    in_data[3].color[3] = 36.0f;

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

    XCTAssertEqual(vertices[0].color[0], 21.0f);
    XCTAssertEqual(vertices[0].color[1], 22.0f);
    XCTAssertEqual(vertices[0].color[2], 23.0f);
    XCTAssertEqual(vertices[0].color[3], 24.0f);
    XCTAssertEqual(vertices[1].color[0], 25.0f);
    XCTAssertEqual(vertices[1].color[1], 26.0f);
    XCTAssertEqual(vertices[1].color[2], 27.0f);
    XCTAssertEqual(vertices[1].color[3], 28.0f);
    XCTAssertEqual(vertices[2].color[0], 29.0f);
    XCTAssertEqual(vertices[2].color[1], 30.0f);
    XCTAssertEqual(vertices[2].color[2], 31.0f);
    XCTAssertEqual(vertices[2].color[3], 32.0f);
    XCTAssertEqual(vertices[3].color[0], 33.0f);
    XCTAssertEqual(vertices[3].color[1], 34.0f);
    XCTAssertEqual(vertices[3].color[2], 35.0f);
    XCTAssertEqual(vertices[3].color[3], 36.0f);

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

    in_data[0].color[0] = 121.0f;
    in_data[0].color[1] = 122.0f;
    in_data[0].color[2] = 123.0f;
    in_data[0].color[3] = 124.0f;
    in_data[1].color[0] = 125.0f;
    in_data[1].color[1] = 126.0f;
    in_data[1].color[2] = 127.0f;
    in_data[1].color[3] = 128.0f;
    in_data[2].color[0] = 129.0f;
    in_data[2].color[1] = 130.0f;
    in_data[2].color[2] = 131.0f;
    in_data[2].color[3] = 132.0f;
    in_data[3].color[0] = 133.0f;
    in_data[3].color[1] = 134.0f;
    in_data[3].color[2] = 135.0f;
    in_data[3].color[3] = 136.0f;

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

    XCTAssertEqual(vertices[4].color[0], 121.0f);
    XCTAssertEqual(vertices[4].color[1], 122.0f);
    XCTAssertEqual(vertices[4].color[2], 123.0f);
    XCTAssertEqual(vertices[4].color[3], 124.0f);
    XCTAssertEqual(vertices[5].color[0], 125.0f);
    XCTAssertEqual(vertices[5].color[1], 126.0f);
    XCTAssertEqual(vertices[5].color[2], 127.0f);
    XCTAssertEqual(vertices[5].color[3], 128.0f);
    XCTAssertEqual(vertices[6].color[0], 129.0f);
    XCTAssertEqual(vertices[6].color[1], 130.0f);
    XCTAssertEqual(vertices[6].color[2], 131.0f);
    XCTAssertEqual(vertices[6].color[3], 132.0f);
    XCTAssertEqual(vertices[7].color[0], 133.0f);
    XCTAssertEqual(vertices[7].color[1], 134.0f);
    XCTAssertEqual(vertices[7].color[2], 135.0f);
    XCTAssertEqual(vertices[7].color[3], 136.0f);
}

- (void)test_set_square_count {
    auto sq_mesh_data = ui::make_square_mesh_data(4);

    XCTAssertEqual(sq_mesh_data.dynamic_mesh_data().index_count(), 4 * 6);

    sq_mesh_data.set_square_count(2);

    XCTAssertEqual(sq_mesh_data.dynamic_mesh_data().index_count(), 2 * 6);
}

- (void)test_max_square_count {
    auto sq_mesh_data = ui::make_square_mesh_data(4);

    XCTAssertEqual(sq_mesh_data.max_square_count(), 4);

    sq_mesh_data.set_square_count(2);

    XCTAssertEqual(sq_mesh_data.max_square_count(), 4);
}

- (void)test_write_vertex {
    auto sq_mesh_data = ui::make_square_mesh_data(1);
    auto vertices = sq_mesh_data.dynamic_mesh_data().vertices();

    sq_mesh_data.write_vertex(0, [](ui::vertex2d_square_t &square) {
        square.v[0].position.x = 0.1f;
        square.v[0].position.y = 0.2f;
        square.v[1].position.x = 0.3f;
        square.v[1].position.y = 0.4f;
        square.v[2].position.x = 0.5f;
        square.v[2].position.y = 0.6f;
        square.v[3].position.x = 0.7f;
        square.v[3].position.y = 0.8f;

        square.v[0].tex_coord.x = 1.1f;
        square.v[0].tex_coord.y = 1.2f;
        square.v[1].tex_coord.x = 1.3f;
        square.v[1].tex_coord.y = 1.4f;
        square.v[2].tex_coord.x = 1.5f;
        square.v[2].tex_coord.y = 1.6f;
        square.v[3].tex_coord.x = 1.7f;
        square.v[3].tex_coord.y = 1.8f;

        square.v[0].color[0] = 2.1f;
        square.v[0].color[1] = 2.2f;
        square.v[0].color[2] = 2.3f;
        square.v[0].color[3] = 2.4f;
        square.v[1].color[0] = 2.5f;
        square.v[1].color[1] = 2.6f;
        square.v[1].color[2] = 2.7f;
        square.v[1].color[3] = 2.8f;
        square.v[2].color[0] = 2.9f;
        square.v[2].color[1] = 3.0f;
        square.v[2].color[2] = 3.1f;
        square.v[2].color[3] = 3.2f;
        square.v[3].color[0] = 3.3f;
        square.v[3].color[1] = 3.4f;
        square.v[3].color[2] = 3.5f;
        square.v[3].color[3] = 3.6f;
    });

    XCTAssertEqual(vertices[0].position.x, 0.1f);
    XCTAssertEqual(vertices[0].position.y, 0.2f);
    XCTAssertEqual(vertices[1].position.x, 0.3f);
    XCTAssertEqual(vertices[1].position.y, 0.4f);
    XCTAssertEqual(vertices[2].position.x, 0.5f);
    XCTAssertEqual(vertices[2].position.y, 0.6f);
    XCTAssertEqual(vertices[3].position.x, 0.7f);
    XCTAssertEqual(vertices[3].position.y, 0.8f);

    XCTAssertEqual(vertices[0].tex_coord.x, 1.1f);
    XCTAssertEqual(vertices[0].tex_coord.y, 1.2f);
    XCTAssertEqual(vertices[1].tex_coord.x, 1.3f);
    XCTAssertEqual(vertices[1].tex_coord.y, 1.4f);
    XCTAssertEqual(vertices[2].tex_coord.x, 1.5f);
    XCTAssertEqual(vertices[2].tex_coord.y, 1.6f);
    XCTAssertEqual(vertices[3].tex_coord.x, 1.7f);
    XCTAssertEqual(vertices[3].tex_coord.y, 1.8f);

    XCTAssertEqual(vertices[0].color[0], 2.1f);
    XCTAssertEqual(vertices[0].color[1], 2.2f);
    XCTAssertEqual(vertices[0].color[2], 2.3f);
    XCTAssertEqual(vertices[0].color[3], 2.4f);
    XCTAssertEqual(vertices[1].color[0], 2.5f);
    XCTAssertEqual(vertices[1].color[1], 2.6f);
    XCTAssertEqual(vertices[1].color[2], 2.7f);
    XCTAssertEqual(vertices[1].color[3], 2.8f);
    XCTAssertEqual(vertices[2].color[0], 2.9f);
    XCTAssertEqual(vertices[2].color[1], 3.0f);
    XCTAssertEqual(vertices[2].color[2], 3.1f);
    XCTAssertEqual(vertices[2].color[3], 3.2f);
    XCTAssertEqual(vertices[3].color[0], 3.3f);
    XCTAssertEqual(vertices[3].color[1], 3.4f);
    XCTAssertEqual(vertices[3].color[2], 3.5f);
    XCTAssertEqual(vertices[3].color[3], 3.6f);
}

@end
