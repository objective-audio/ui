//
//  yas_ui_mesh_data_tests.mm
//

#import <XCTest/XCTest.h>
#import <cpp_utils/yas_objc_ptr.h>
#import <ui/yas_ui_umbrella.h>
#import <iostream>
#import <sstream>

using namespace yas;

@interface yas_ui_mesh_data_tests : XCTestCase

@end

@implementation yas_ui_mesh_data_tests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)test_create_mesh_data {
    auto mesh_data = ui::mesh_data::make_shared({.vertex_count = 4, .index_count = 6});

    XCTAssertEqual(mesh_data->vertex_count(), 4);
    XCTAssertEqual(mesh_data->index_count(), 6);

    XCTAssertTrue(mesh_data->metal());
    XCTAssertTrue(mesh_data->renderable());

    XCTAssertEqual(mesh_data->renderable()->vertex_buffer_byte_offset(), 0);
    XCTAssertEqual(mesh_data->renderable()->index_buffer_byte_offset(), 0);
}

- (void)test_create_dynamic_mesh_data {
    auto mesh_data = ui::dynamic_mesh_data::make_shared({.vertex_count = 4, .index_count = 6});

    XCTAssertEqual(mesh_data->vertex_count(), 4);
    XCTAssertEqual(mesh_data->index_count(), 6);
    XCTAssertEqual(mesh_data->max_vertex_count(), 4);
    XCTAssertEqual(mesh_data->max_index_count(), 6);

    XCTAssertTrue(mesh_data->metal());
    XCTAssertTrue(mesh_data->renderable());
}

- (void)test_write_mesh_data {
    auto mesh_data = ui::mesh_data::make_shared({.vertex_count = 4, .index_count = 6});

    mesh_data->write([self](auto &vertices, auto &indices) {
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

    XCTAssertEqual(mesh_data->vertices()[0].position.x, 0.0f);
    XCTAssertEqual(mesh_data->vertices()[0].position.y, 1.0f);
    XCTAssertEqual(mesh_data->vertices()[1].position.x, 2.0f);
    XCTAssertEqual(mesh_data->vertices()[1].position.y, 3.0f);
    XCTAssertEqual(mesh_data->vertices()[2].position.x, 4.0f);
    XCTAssertEqual(mesh_data->vertices()[2].position.y, 5.0f);
    XCTAssertEqual(mesh_data->vertices()[3].position.x, 6.0f);
    XCTAssertEqual(mesh_data->vertices()[3].position.y, 7.0f);

    XCTAssertEqual(mesh_data->indices()[0], 20.0f);
    XCTAssertEqual(mesh_data->indices()[1], 21.0f);
    XCTAssertEqual(mesh_data->indices()[2], 22.0f);
    XCTAssertEqual(mesh_data->indices()[3], 23.0f);
    XCTAssertEqual(mesh_data->indices()[4], 24.0f);
    XCTAssertEqual(mesh_data->indices()[5], 25.0f);
}

- (void)test_set_variables_dynamic_mesh_data {
    auto mesh_data = ui::dynamic_mesh_data::make_shared({.vertex_count = 4, .index_count = 6});

    XCTAssertEqual(mesh_data->vertex_count(), 4);
    XCTAssertEqual(mesh_data->index_count(), 6);
    XCTAssertEqual(mesh_data->max_vertex_count(), 4);
    XCTAssertEqual(mesh_data->max_index_count(), 6);

    mesh_data->set_vertex_count(0);
    mesh_data->set_index_count(0);

    XCTAssertEqual(mesh_data->vertex_count(), 0);
    XCTAssertEqual(mesh_data->index_count(), 0);
    XCTAssertEqual(mesh_data->max_vertex_count(), 4);
    XCTAssertEqual(mesh_data->max_index_count(), 6);

    mesh_data->set_vertex_count(4);
    mesh_data->set_index_count(6);

    XCTAssertEqual(mesh_data->vertex_count(), 4);
    XCTAssertEqual(mesh_data->index_count(), 6);

    XCTAssertThrows(mesh_data->set_vertex_count(5));
    XCTAssertThrows(mesh_data->set_index_count(7));
}

- (void)test_clear_updates {
    auto mesh_data = ui::mesh_data::make_shared({.vertex_count = 1, .index_count = 1});

    XCTAssertTrue(mesh_data->renderable()->updates().flags.any());

    mesh_data->renderable()->clear_updates();

    XCTAssertFalse(mesh_data->renderable()->updates().flags.any());
}

- (void)test_updates {
    auto mesh_data = ui::dynamic_mesh_data::make_shared({.vertex_count = 4, .index_count = 6});

    mesh_data->renderable()->clear_updates();
    mesh_data->set_index_count(1);

    XCTAssertEqual(mesh_data->renderable()->updates().flags.count(), 1);
    XCTAssertTrue(mesh_data->renderable()->updates().test(ui::mesh_data_update_reason::index_count));

    mesh_data->renderable()->clear_updates();
    mesh_data->set_vertex_count(2);

    XCTAssertEqual(mesh_data->renderable()->updates().flags.count(), 1);
    XCTAssertTrue(mesh_data->renderable()->updates().test(ui::mesh_data_update_reason::vertex_count));

    mesh_data->renderable()->clear_updates();
    mesh_data->write([](auto &, auto &) {});

    XCTAssertEqual(mesh_data->renderable()->updates().flags.count(), 2);
    XCTAssertTrue(mesh_data->renderable()->updates().test(ui::mesh_data_update_reason::data));
    XCTAssertTrue(mesh_data->renderable()->updates().test(ui::mesh_data_update_reason::render_buffer));
}

- (void)test_metal_setup {
    auto device = objc_ptr_with_move_object(MTLCreateSystemDefaultDevice());
    if (!device) {
        std::cout << "skip : " << __PRETTY_FUNCTION__ << std::endl;
        return;
    }

    auto metal_system = ui::metal_system::make_shared(device.object());

    auto mesh_data = ui::mesh_data::make_shared({.vertex_count = 1, .index_count = 1});

    XCTAssertTrue(mesh_data->metal().metal_setup(metal_system));
}

- (void)test_mesh_data_update_reason_to_string {
    XCTAssertEqual(to_string(ui::mesh_data_update_reason::data), "data");
    XCTAssertEqual(to_string(ui::mesh_data_update_reason::vertex_count), "vertex_count");
    XCTAssertEqual(to_string(ui::mesh_data_update_reason::index_count), "index_count");
    XCTAssertEqual(to_string(ui::mesh_data_update_reason::render_buffer), "render_buffer");
    XCTAssertEqual(to_string(ui::mesh_data_update_reason::count), "count");
}

- (void)test_mesh_data_update_reason_ostream {
    auto const reasons = {ui::mesh_data_update_reason::data, ui::mesh_data_update_reason::vertex_count,
                          ui::mesh_data_update_reason::index_count, ui::mesh_data_update_reason::render_buffer,
                          ui::mesh_data_update_reason::count};

    for (auto const &reason : reasons) {
        std::ostringstream stream;
        stream << reason;
        XCTAssertEqual(stream.str(), to_string(reason));
    }
}

@end
