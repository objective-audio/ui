//
//  yas_ui_mesh_data_tests.mm
//

#import <XCTest/XCTest.h>
#import <ui/yas_ui_umbrella.h>
#import <iostream>
#import <sstream>

using namespace yas;
using namespace yas::ui;

@interface yas_ui_mesh_data_tests : XCTestCase

@end

@implementation yas_ui_mesh_data_tests

- (void)test_create_vertex_data {
    auto const data = static_mesh_vertex_data::make_shared(4);

    XCTAssertEqual(data->count(), 4);
    XCTAssertEqual(data->byte_offset(), 0);
}

- (void)test_create_index_data {
    auto const data = static_mesh_index_data::make_shared(6);

    XCTAssertEqual(data->count(), 6);
    XCTAssertEqual(data->byte_offset(), 0);
}

- (void)test_create_dynamic_vertex_data {
    auto const data = dynamic_mesh_vertex_data::make_shared(4);

    XCTAssertEqual(data->count(), 4);
    XCTAssertEqual(data->max_count(), 4);

    XCTAssertTrue(data);
}

- (void)test_create_dynamic_index_data {
    auto const data = dynamic_mesh_index_data::make_shared(6);

    XCTAssertEqual(data->count(), 6);
    XCTAssertEqual(data->max_count(), 6);

    XCTAssertTrue(data);
}

- (void)test_write_vertex_data {
    auto const data = static_mesh_vertex_data::make_shared(4);

    data->write_once([self](auto &vertices) {
        XCTAssertEqual(vertices.size(), 4);

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
    });

    XCTAssertEqual(data->raw_data()[0].position.x, 0.0f);
    XCTAssertEqual(data->raw_data()[0].position.y, 1.0f);
    XCTAssertEqual(data->raw_data()[1].position.x, 2.0f);
    XCTAssertEqual(data->raw_data()[1].position.y, 3.0f);
    XCTAssertEqual(data->raw_data()[2].position.x, 4.0f);
    XCTAssertEqual(data->raw_data()[2].position.y, 5.0f);
    XCTAssertEqual(data->raw_data()[3].position.x, 6.0f);
    XCTAssertEqual(data->raw_data()[3].position.y, 7.0f);
}

- (void)test_write_index_data {
    auto const data = static_mesh_index_data::make_shared(6);

    data->write_once([self](auto &indices) {
        XCTAssertEqual(indices.size(), 6);

        indices[0] = 20.0f;
        indices[1] = 21.0f;
        indices[2] = 22.0f;
        indices[3] = 23.0f;
        indices[4] = 24.0f;
        indices[5] = 25.0f;
    });

    XCTAssertEqual(data->raw_data()[0], 20.0f);
    XCTAssertEqual(data->raw_data()[1], 21.0f);
    XCTAssertEqual(data->raw_data()[2], 22.0f);
    XCTAssertEqual(data->raw_data()[3], 23.0f);
    XCTAssertEqual(data->raw_data()[4], 24.0f);
    XCTAssertEqual(data->raw_data()[5], 25.0f);
}

- (void)test_set_variables_dynamic_vertex_data {
    auto const data = dynamic_mesh_vertex_data::make_shared(4);

    XCTAssertEqual(data->count(), 4);
    XCTAssertEqual(data->max_count(), 4);

    data->set_count(0);

    XCTAssertEqual(data->count(), 0);
    XCTAssertEqual(data->max_count(), 4);

    data->set_count(4);

    XCTAssertEqual(data->count(), 4);

    XCTAssertThrows(data->set_count(5));
}

- (void)test_set_variables_dynamic_index_data {
    auto const data = dynamic_mesh_index_data::make_shared(6);

    XCTAssertEqual(data->count(), 6);
    XCTAssertEqual(data->max_count(), 6);

    data->set_count(0);

    XCTAssertEqual(data->count(), 0);
    XCTAssertEqual(data->max_count(), 6);

    data->set_count(6);

    XCTAssertEqual(data->count(), 6);

    XCTAssertThrows(data->set_count(7));
}

- (void)test_clear_updates {
    auto const data = static_mesh_vertex_data::make_shared(1);

    XCTAssertTrue(data->updates().flags.any());

    data->clear_updates();

    XCTAssertFalse(data->updates().flags.any());
}

- (void)test_updates {
    auto const data = dynamic_mesh_vertex_data::make_shared(4);

    data->clear_updates();
    data->set_count(1);

    XCTAssertEqual(data->updates().flags.count(), 1);
    XCTAssertTrue(data->updates().test(mesh_data_update_reason::data_count));

    data->clear_updates();
    data->write([](auto &) {});

    XCTAssertEqual(data->updates().flags.count(), 2);
    XCTAssertTrue(data->updates().test(mesh_data_update_reason::data_content));
    XCTAssertTrue(data->updates().test(mesh_data_update_reason::render_buffer));
}

- (void)test_metal_setup {
    auto device = objc_ptr_with_move_object(MTLCreateSystemDefaultDevice());
    if (!device) {
        std::cout << "skip : " << __PRETTY_FUNCTION__ << std::endl;
        return;
    }

    auto const metal_system = metal_system::make_shared(device.object(), nil);

    auto const data = static_mesh_vertex_data::make_shared(1);

    XCTAssertTrue(data->metal_setup(metal_system));
}

- (void)test_mesh_data_update_reason_to_string {
    XCTAssertEqual(to_string(mesh_data_update_reason::data_content), "data_content");
    XCTAssertEqual(to_string(mesh_data_update_reason::data_count), "data_count");
    XCTAssertEqual(to_string(mesh_data_update_reason::render_buffer), "render_buffer");
    XCTAssertEqual(to_string(mesh_data_update_reason::count), "count");
}

- (void)test_mesh_data_update_reason_ostream {
    auto const reasons = {mesh_data_update_reason::data_content, mesh_data_update_reason::data_count,
                          mesh_data_update_reason::render_buffer, mesh_data_update_reason::count};

    for (auto const &reason : reasons) {
        std::ostringstream stream;
        stream << reason;
        XCTAssertEqual(stream.str(), to_string(reason));
    }
}

@end
