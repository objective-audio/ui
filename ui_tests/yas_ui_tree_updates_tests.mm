//
//  yas_ui_tree_updates_tests.mm
//

#import <XCTest/XCTest.h>
#import <ui/ui.h>

using namespace yas;
using namespace yas::ui;

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
    tree_updates updates;

    XCTAssertFalse(updates.is_any_updated());

    updates = tree_updates{};
    updates.node_updates.set(node_update_reason::batch);
    XCTAssertTrue(updates.is_any_updated());

    updates = tree_updates{};
    updates.vertex_data_updates.set(mesh_data_update_reason::data_content);
    XCTAssertTrue(updates.is_any_updated());

    updates = tree_updates{};
    updates.index_data_updates.set(mesh_data_update_reason::data_content);
    XCTAssertTrue(updates.is_any_updated());
}

- (void)test_is_collider_updated {
    tree_updates updates;

    XCTAssertFalse(updates.is_collider_updated());

    updates = tree_updates{};
    updates.node_updates.set(node_update_reason::enabled);
    XCTAssertTrue(updates.is_collider_updated());

    updates = tree_updates{};
    updates.node_updates.set(node_update_reason::children);
    XCTAssertTrue(updates.is_collider_updated());

    updates = tree_updates{};
    updates.node_updates.set(node_update_reason::collider);
    XCTAssertTrue(updates.is_collider_updated());

    updates = tree_updates{};
    updates.node_updates.set(node_update_reason::batch);
    XCTAssertFalse(updates.is_collider_updated());

    updates = tree_updates{};
    updates.vertex_data_updates.set(mesh_data_update_reason::data_content);
    XCTAssertFalse(updates.is_collider_updated());

    updates = tree_updates{};
    updates.index_data_updates.set(mesh_data_update_reason::data_content);
    XCTAssertFalse(updates.is_collider_updated());
}

- (void)test_batch_building_type_none {
    tree_updates updates;

    XCTAssertEqual(updates.batch_building_type(), batch_building_type::none);

    updates.node_updates.set(node_update_reason::geometry);

    XCTAssertNotEqual(updates.batch_building_type(), batch_building_type::none);
}

- (void)test_batch_building_type_rebuild {
    tree_updates updates;

    updates = tree_updates{};
    updates.node_updates.set(node_update_reason::mesh);
    XCTAssertEqual(updates.batch_building_type(), batch_building_type::rebuild);

    updates = tree_updates{};
    updates.node_updates.set(node_update_reason::enabled);
    XCTAssertEqual(updates.batch_building_type(), batch_building_type::rebuild);

    updates = tree_updates{};
    updates.node_updates.set(node_update_reason::children);
    XCTAssertEqual(updates.batch_building_type(), batch_building_type::rebuild);

    updates = tree_updates{};
    updates.node_updates.set(node_update_reason::batch);
    XCTAssertEqual(updates.batch_building_type(), batch_building_type::rebuild);

    updates = tree_updates{};
    updates.mesh_updates.set(mesh_update_reason::texture);
    XCTAssertEqual(updates.batch_building_type(), batch_building_type::rebuild);

    updates = tree_updates{};
    updates.vertex_data_updates.set(mesh_data_update_reason::data_count);
    XCTAssertEqual(updates.batch_building_type(), batch_building_type::rebuild);

    updates = tree_updates{};
    updates.index_data_updates.set(mesh_data_update_reason::data_count);
    XCTAssertEqual(updates.batch_building_type(), batch_building_type::rebuild);
}

- (void)test_batch_building_type_overwrite {
    tree_updates updates;
    updates.node_updates.set({node_update_reason::collider, node_update_reason::geometry});
    updates.mesh_updates.set({mesh_update_reason::use_mesh_color, mesh_update_reason::color});
    updates.vertex_data_updates.set({mesh_data_update_reason::data_content, mesh_data_update_reason::render_buffer});
    updates.index_data_updates.set({mesh_data_update_reason::data_content, mesh_data_update_reason::render_buffer});

    XCTAssertEqual(updates.batch_building_type(), batch_building_type::overwrite);
}

@end
