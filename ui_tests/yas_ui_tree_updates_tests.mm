//
//  yas_ui_tree_updates_tests.mm
//

#import <XCTest/XCTest.h>
#import <ui/ui.h>

using namespace yas;

@interface yas_ui_tree_updates_tests : XCTestCase

@end

@implementation yas_ui_tree_updates_tests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)test_is_any_updated {
    ui::tree_updates updates;

    XCTAssertFalse(updates.is_any_updated());

    updates = ui::tree_updates{};
    updates.node_updates.set(ui::node_update_reason::batch);
    XCTAssertTrue(updates.is_any_updated());

    updates = ui::tree_updates{};
    updates.mesh_updates.set(ui::mesh_update_reason::mesh_data);
    XCTAssertTrue(updates.is_any_updated());

    updates = ui::tree_updates{};
    updates.mesh_data_updates.set(ui::mesh_data_update_reason::data);
    XCTAssertTrue(updates.is_any_updated());
}

- (void)test_is_collider_updated {
    ui::tree_updates updates;

    XCTAssertFalse(updates.is_collider_updated());

    updates = ui::tree_updates{};
    updates.node_updates.set(ui::node_update_reason::enabled);
    XCTAssertTrue(updates.is_collider_updated());

    updates = ui::tree_updates{};
    updates.node_updates.set(ui::node_update_reason::children);
    XCTAssertTrue(updates.is_collider_updated());

    updates = ui::tree_updates{};
    updates.node_updates.set(ui::node_update_reason::collider);
    XCTAssertTrue(updates.is_collider_updated());

    updates = ui::tree_updates{};
    updates.node_updates.set(ui::node_update_reason::batch);
    XCTAssertFalse(updates.is_collider_updated());

    updates = ui::tree_updates{};
    updates.mesh_updates.set(ui::mesh_update_reason::mesh_data);
    XCTAssertFalse(updates.is_collider_updated());

    updates = ui::tree_updates{};
    updates.mesh_data_updates.set(ui::mesh_data_update_reason::data);
    XCTAssertFalse(updates.is_collider_updated());
}

- (void)test_batch_building_type_none {
    ui::tree_updates updates;

    XCTAssertEqual(updates.batch_building_type(), ui::batch_building_type::none);

    updates.node_updates.set(ui::node_update_reason::geometry);

    XCTAssertNotEqual(updates.batch_building_type(), ui::batch_building_type::none);
}

- (void)test_batch_building_type_rebuild {
    ui::tree_updates updates;

    updates = ui::tree_updates{};
    updates.node_updates.set(ui::node_update_reason::mesh);
    XCTAssertEqual(updates.batch_building_type(), ui::batch_building_type::rebuild);

    updates = ui::tree_updates{};
    updates.node_updates.set(ui::node_update_reason::enabled);
    XCTAssertEqual(updates.batch_building_type(), ui::batch_building_type::rebuild);

    updates = ui::tree_updates{};
    updates.node_updates.set(ui::node_update_reason::children);
    XCTAssertEqual(updates.batch_building_type(), ui::batch_building_type::rebuild);

    updates = ui::tree_updates{};
    updates.node_updates.set(ui::node_update_reason::batch);
    XCTAssertEqual(updates.batch_building_type(), ui::batch_building_type::rebuild);

    updates = ui::tree_updates{};
    updates.mesh_updates.set(ui::mesh_update_reason::texture);
    XCTAssertEqual(updates.batch_building_type(), ui::batch_building_type::rebuild);

    updates = ui::tree_updates{};
    updates.mesh_updates.set(ui::mesh_update_reason::mesh_data);
    XCTAssertEqual(updates.batch_building_type(), ui::batch_building_type::rebuild);

    updates = ui::tree_updates{};
    updates.mesh_data_updates.set(ui::mesh_data_update_reason::index_count);
    XCTAssertEqual(updates.batch_building_type(), ui::batch_building_type::rebuild);

    updates = ui::tree_updates{};
    updates.mesh_data_updates.set(ui::mesh_data_update_reason::vertex_count);
    XCTAssertEqual(updates.batch_building_type(), ui::batch_building_type::rebuild);
}

- (void)test_batch_building_type_overwrite {
    ui::tree_updates updates;
    updates.node_updates.set({ui::node_update_reason::collider, ui::node_update_reason::geometry});
    updates.mesh_updates.set({ui::mesh_update_reason::primitive_type, ui::mesh_update_reason::use_mesh_color,
                              ui::mesh_update_reason::color});
    updates.mesh_data_updates.set({ui::mesh_data_update_reason::data, ui::mesh_data_update_reason::render_buffer});

    XCTAssertEqual(updates.batch_building_type(), ui::batch_building_type::overwrite);
}

@end
