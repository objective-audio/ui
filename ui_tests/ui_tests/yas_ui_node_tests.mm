//
//  yas_ui_node_tests.mm
//

#import <XCTest/XCTest.h>
#import <iostream>
#import "yas_objc_ptr.h"
#import "yas_observing.h"
#import "yas_ui_batch.h"
#import "yas_ui_collider.h"
#import "yas_ui_mesh.h"
#import "yas_ui_mesh_data.h"
#import "yas_ui_node.h"
#import "yas_ui_renderer.h"

using namespace yas;

@interface yas_ui_node_tests : XCTestCase

@end

@implementation yas_ui_node_tests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)test_create {
    ui::node node;

    XCTAssertEqual(node.position().x, 0.0f);
    XCTAssertEqual(node.position().y, 0.0f);
    XCTAssertEqual(node.angle(), 0.0f);
    XCTAssertEqual(node.scale().width, 1.0f);
    XCTAssertEqual(node.scale().height, 1.0f);

    XCTAssertEqual(node.color().red, 1.0f);
    XCTAssertEqual(node.color().green, 1.0f);
    XCTAssertEqual(node.color().blue, 1.0f);
    XCTAssertEqual(node.alpha(), 1.0f);

    XCTAssertFalse(node.mesh());
    XCTAssertFalse(node.collider());

    XCTAssertEqual(node.children().size(), 0);
    XCTAssertFalse(node.parent());
    XCTAssertFalse(node.renderer());

    XCTAssertTrue(node.is_enabled());

    XCTAssertTrue(node.renderable());
    XCTAssertTrue(node.metal());
}

- (void)test_create_null {
    ui::node node{nullptr};

    XCTAssertFalse(node);
}

- (void)test_set_variables {
    ui::node node;
    ui::mesh mesh;
    ui::collider collider;
    ui::batch batch;

    node.set_position({1.0f, 2.0f});
    node.set_angle(3.0f);
    node.set_scale({4.0f, 5.0f});
    node.set_color({0.1f, 0.2f, 0.3f});
    node.set_alpha(0.4f);

    node.set_enabled(true);

    XCTAssertEqual(node.position().x, 1.0f);
    XCTAssertEqual(node.position().y, 2.0f);
    XCTAssertEqual(node.angle(), 3.0f);
    XCTAssertEqual(node.scale().width, 4.0f);
    XCTAssertEqual(node.scale().height, 5.0f);
    XCTAssertEqual(node.color().red, 0.1f);
    XCTAssertEqual(node.color().green, 0.2f);
    XCTAssertEqual(node.color().blue, 0.3f);
    XCTAssertEqual(node.alpha(), 0.4f);

    node.set_mesh(mesh);
    XCTAssertTrue(node.mesh());
    XCTAssertEqual(node.mesh(), mesh);

    node.set_collider(collider);
    XCTAssertTrue(node.collider());
    XCTAssertEqual(node.collider(), collider);

    node.set_batch(batch);
    XCTAssertTrue(node.batch());
    XCTAssertEqual(node.batch(), batch);

    node.set_batch(nullptr);
    XCTAssertFalse(node.batch());

    XCTAssertTrue(node.is_enabled());
}

- (void)test_const_variables {
    ui::node node;
    ui::node const &const_node = node;

    XCTAssertFalse(const_node.mesh());
    XCTAssertFalse(const_node.collider());

    node.set_mesh(ui::mesh{});
    node.set_collider(ui::collider{});

    XCTAssertTrue(const_node.mesh());
    XCTAssertTrue(const_node.collider());
    XCTAssertEqual(const_node.children().size(), 0);
}

- (void)set_color_to_mesh {
    ui::node node;
    ui::mesh mesh;

    XCTAssertEqual(mesh.color()[0], 1.0f);
    XCTAssertEqual(mesh.color()[1], 1.0f);
    XCTAssertEqual(mesh.color()[2], 1.0f);
    XCTAssertEqual(mesh.color()[3], 1.0f);

    node.set_color({0.25f, 0.5f, 0.75f});
    node.set_alpha(0.125f);

    node.set_mesh(mesh);

    XCTAssertEqual(mesh.color()[0], 0.25f);
    XCTAssertEqual(mesh.color()[1], 0.5f);
    XCTAssertEqual(mesh.color()[2], 0.75f);
    XCTAssertEqual(mesh.color()[3], 0.125f);

    node.set_color({0.1f, 0.2f, 0.3f});
    node.set_alpha(0.4f);

    XCTAssertEqual(mesh.color()[0], 0.1f);
    XCTAssertEqual(mesh.color()[1], 0.2f);
    XCTAssertEqual(mesh.color()[2], 0.3f);
    XCTAssertEqual(mesh.color()[3], 0.4f);
}

- (void)test_is_equal {
    ui::node node1;
    ui::node node1b = node1;
    ui::node node2;

    XCTAssertTrue(node1 == node1);
    XCTAssertTrue(node1 == node1b);
    XCTAssertFalse(node1 == node2);

    XCTAssertFalse(node1 != node1);
    XCTAssertFalse(node1 != node1b);
    XCTAssertTrue(node1 != node2);
}

- (void)test_hierarchie {
    ui::node parent_node;

    ui::node sub_node1;
    ui::node sub_node2;

    XCTAssertEqual(parent_node.children().size(), 0);
    XCTAssertFalse(sub_node1.parent());
    XCTAssertFalse(sub_node2.parent());

    parent_node.push_back_sub_node(sub_node1);

    XCTAssertEqual(parent_node.children().size(), 1);
    XCTAssertTrue(sub_node1.parent());

    parent_node.push_back_sub_node(sub_node2);

    XCTAssertEqual(parent_node.children().size(), 2);
    XCTAssertTrue(sub_node1.parent());
    XCTAssertTrue(sub_node2.parent());

    XCTAssertEqual(parent_node.children().at(0), sub_node1);
    XCTAssertEqual(parent_node.children().at(1), sub_node2);
    XCTAssertEqual(sub_node1.parent(), parent_node);
    XCTAssertEqual(sub_node2.parent(), parent_node);

    sub_node1.remove_from_super_node();

    XCTAssertEqual(parent_node.children().size(), 1);
    XCTAssertFalse(sub_node1.parent());
    XCTAssertTrue(sub_node2.parent());

    XCTAssertEqual(parent_node.children().at(0), sub_node2);

    sub_node2.remove_from_super_node();

    XCTAssertEqual(parent_node.children().size(), 0);
    XCTAssertFalse(sub_node2.parent());
}

- (void)test_push_front_sub_node {
    ui::node parent_node;

    ui::node sub_node1;
    ui::node sub_node2;

    parent_node.push_back_sub_node(sub_node2);
    parent_node.push_front_sub_node(sub_node1);

    XCTAssertEqual(parent_node.children().at(0), sub_node1);
    XCTAssertEqual(parent_node.children().at(1), sub_node2);
}

- (void)test_insert_sub_node {
    ui::node parent_node;

    ui::node sub_node1;
    ui::node sub_node2;
    ui::node sub_node3;

    parent_node.push_back_sub_node(sub_node1);
    parent_node.push_back_sub_node(sub_node3);
    parent_node.insert_sub_node(sub_node2, 1);

    XCTAssertEqual(parent_node.children().at(0), sub_node1);
    XCTAssertEqual(parent_node.children().at(1), sub_node2);
    XCTAssertEqual(parent_node.children().at(2), sub_node3);
}

- (void)test_renderable_node {
    id<MTLDevice> device = nil;

    ui::node node;
    ui::renderer renderer{device};

    auto &renderable = node.renderable();

    XCTAssertFalse(renderable.renderer());

    renderable.set_renderer(renderer);

    XCTAssertTrue(renderable.renderer());
    XCTAssertEqual(renderable.renderer(), renderer);
}

- (void)test_add_and_remove_node_observed {
    ui::node parent_node;
    ui::node sub_node;
    int observer_called_count = 0;
    bool added_to_super_called = false;
    bool removed_from_super_called = false;

    auto observer = sub_node.subject().make_wild_card_observer(
        [&observer_called_count, &added_to_super_called, &removed_from_super_called](auto const &context) {
            switch (context.key) {
                case ui::node_method::added_to_super:
                    added_to_super_called = true;
                    break;
                case ui::node_method::removed_from_super:
                    removed_from_super_called = true;
                    break;

                default:
                    break;
            }
            ++observer_called_count;
        });

    parent_node.push_back_sub_node(sub_node);

    XCTAssertTrue(added_to_super_called);

    sub_node.remove_from_super_node();

    XCTAssertTrue(removed_from_super_called);

    XCTAssertEqual(observer_called_count, 2);
}

- (void)test_method_undispatched {
    id<MTLDevice> device = nil;

    ui::node node;
    ui::renderer renderer{device};

    std::shared_ptr<ui::node_method> called_method = nullptr;

    auto observer = node.subject().make_wild_card_observer([&called_method](auto const &context) mutable {
        auto const &method = context.key;
        if (method != ui::node_method::added_to_super && method != ui::node_method::removed_from_super) {
            called_method = std::make_shared<ui::node_method>(context.key);
        }
    });

    node.set_position({1.0f, 2.0f});
    XCTAssertFalse(called_method);
    node.set_angle(90.0f);
    XCTAssertFalse(called_method);
    node.set_scale({3.0f, 4.0f});
    XCTAssertFalse(called_method);
    node.set_color({1.0f, 2.0f, 3.0f});
    XCTAssertFalse(called_method);
    node.set_alpha(5.0f);
    XCTAssertFalse(called_method);
    node.set_enabled(false);
    XCTAssertFalse(called_method);
    node.set_mesh(ui::mesh{});
    XCTAssertFalse(called_method);
    node.set_collider(ui::collider{});
    XCTAssertFalse(called_method);

    ui::node parent;
    parent.push_back_sub_node(node);
    XCTAssertFalse(called_method);

    node.renderable().set_renderer(renderer);
    XCTAssertFalse(called_method);
}

- (void)test_method_dispatched {
    std::shared_ptr<ui::node_method> called_method = nullptr;

    auto make_observer = [&called_method](ui::node &node) {
        return node.subject().make_wild_card_observer([&called_method](auto const &context) mutable {
            auto const &method = context.key;
            if (method != ui::node_method::added_to_super && method != ui::node_method::removed_from_super) {
                called_method = std::make_shared<ui::node_method>(context.key);
            }
        });
    };

    {
        ui::node node;
        node.dispatch_method(ui::node_method::position_changed);
        auto observer = make_observer(node);
        node.set_position({1.0f, 2.0f});
        XCTAssertEqual(*called_method, ui::node_method::position_changed);
    }

    called_method = nullptr;

    {
        ui::node node;
        node.dispatch_method(ui::node_method::angle_changed);
        auto observer = make_observer(node);
        node.set_angle(90.0f);
        XCTAssertEqual(*called_method, ui::node_method::angle_changed);
    }

    called_method = nullptr;

    {
        ui::node node;
        node.dispatch_method(ui::node_method::scale_changed);
        auto observer = make_observer(node);
        node.set_scale({3.0f, 4.0f});
        XCTAssertEqual(*called_method, ui::node_method::scale_changed);
    }

    called_method = nullptr;

    {
        ui::node node;
        node.dispatch_method(ui::node_method::color_changed);
        auto observer = make_observer(node);
        node.set_color({1.0f, 2.0f, 3.0f});
        XCTAssertEqual(*called_method, ui::node_method::color_changed);
    }

    called_method = nullptr;

    {
        ui::node node;
        node.dispatch_method(ui::node_method::alpha_changed);
        auto observer = make_observer(node);
        node.set_alpha(0.5f);
        XCTAssertEqual(*called_method, ui::node_method::alpha_changed);
    }

    called_method = nullptr;

    {
        ui::node node;
        node.dispatch_method(ui::node_method::enabled_changed);
        auto observer = make_observer(node);
        node.set_enabled(false);
        XCTAssertEqual(*called_method, ui::node_method::enabled_changed);
    }

    called_method = nullptr;

    {
        ui::node node;
        node.dispatch_method(ui::node_method::mesh_changed);
        auto observer = make_observer(node);
        node.set_mesh(ui::mesh{});
        XCTAssertEqual(*called_method, ui::node_method::mesh_changed);
    }

    called_method = nullptr;

    {
        ui::node node;
        node.dispatch_method(ui::node_method::collider_changed);
        auto observer = make_observer(node);
        node.set_collider(ui::collider{});
        XCTAssertEqual(*called_method, ui::node_method::collider_changed);
    }

    called_method = nullptr;

    {
        ui::node parent;
        ui::node node;
        node.dispatch_method(ui::node_method::parent_changed);
        auto observer = make_observer(node);
        parent.push_back_sub_node(node);
        XCTAssertEqual(*called_method, ui::node_method::parent_changed);
    }

    called_method = nullptr;

    {
        id<MTLDevice> device = nil;
        ui::renderer renderer{device};
        ui::node node;
        node.dispatch_method(ui::node_method::renderer_changed);
        auto observer = make_observer(node);
        node.renderable().set_renderer(renderer);
        XCTAssertEqual(*called_method, ui::node_method::renderer_changed);
    }

    called_method = nullptr;
}

- (void)test_fetch_updates {
    ui::node node;

    ui::mesh mesh;
    node.set_mesh(mesh);

    ui::dynamic_mesh_data mesh_data{{.vertex_count = 2, .index_count = 2}};
    mesh.set_mesh_data(mesh_data);

    ui::node sub_node;
    node.push_back_sub_node(sub_node);

    ui::tree_updates updates;

    updates = ui::tree_updates{};
    node.renderable().clear_updates();
    node.renderable().fetch_updates(updates);
    XCTAssertFalse(updates.is_any_updated());

    updates = ui::tree_updates{};
    node.renderable().clear_updates();
    node.set_angle(1.0f);
    node.renderable().fetch_updates(updates);
    XCTAssertTrue(updates.is_any_updated());
    XCTAssertEqual(updates.node_updates.flags.count(), 1);
    XCTAssertTrue(updates.node_updates.test(ui::node_update_reason::geometry));
    XCTAssertFalse(updates.mesh_updates.flags.any());
    XCTAssertFalse(updates.mesh_data_updates.flags.any());

    updates = ui::tree_updates{};
    node.renderable().clear_updates();
    mesh.set_use_mesh_color(true);
    node.renderable().fetch_updates(updates);
    XCTAssertTrue(updates.is_any_updated());
    XCTAssertFalse(updates.node_updates.flags.any());
    XCTAssertEqual(updates.mesh_updates.flags.count(), 1);
    XCTAssertTrue(updates.mesh_updates.test(ui::mesh_update_reason::use_mesh_color));
    XCTAssertFalse(updates.mesh_data_updates.flags.any());

    updates = ui::tree_updates{};
    node.renderable().clear_updates();
    mesh_data.set_vertex_count(1);
    node.renderable().fetch_updates(updates);
    XCTAssertTrue(updates.is_any_updated());
    XCTAssertFalse(updates.node_updates.flags.any());
    XCTAssertFalse(updates.mesh_updates.flags.any());
    XCTAssertEqual(updates.mesh_data_updates.flags.count(), 1);
    XCTAssertTrue(updates.mesh_data_updates.test(ui::mesh_data_update_reason::vertex_count));

    updates = ui::tree_updates{};
    node.renderable().clear_updates();
    sub_node.set_enabled(false);
    node.renderable().fetch_updates(updates);
    XCTAssertTrue(updates.is_any_updated());
    XCTAssertEqual(updates.node_updates.flags.count(), 1);
    XCTAssertTrue(updates.node_updates.test(ui::node_update_reason::enabled));
    XCTAssertFalse(updates.mesh_updates.flags.any());
    XCTAssertFalse(updates.mesh_data_updates.flags.any());
}

- (void)test_is_rendering_color_exists {
    ui::node node;

    XCTAssertFalse(node.renderable().is_rendering_color_exists());

    ui::mesh mesh;
    mesh.set_mesh_data(ui::mesh_data{{.vertex_count = 1, .index_count = 1}});
    node.set_mesh(mesh);

    XCTAssertTrue(node.renderable().is_rendering_color_exists());

    node.set_mesh(nullptr);
    ui::node sub_node;
    sub_node.set_mesh(mesh);
    node.push_back_sub_node(sub_node);

    XCTAssertTrue(node.renderable().is_rendering_color_exists());

    node.set_enabled(false);

    XCTAssertFalse(node.renderable().is_rendering_color_exists());
}

- (void)test_node_update_reason_to_string {
    XCTAssertEqual(to_string(ui::node_update_reason::geometry), "geometry");
    XCTAssertEqual(to_string(ui::node_update_reason::mesh), "mesh");
    XCTAssertEqual(to_string(ui::node_update_reason::collider), "collider");
    XCTAssertEqual(to_string(ui::node_update_reason::enabled), "enabled");
    XCTAssertEqual(to_string(ui::node_update_reason::children), "children");
    XCTAssertEqual(to_string(ui::node_update_reason::batch), "batch");
    XCTAssertEqual(to_string(ui::node_update_reason::count), "count");
}

- (void)test_node_update_reason_ostream {
    std::cout << ui::node_update_reason::geometry << std::endl;
    std::cout << ui::node_update_reason::mesh << std::endl;
    std::cout << ui::node_update_reason::collider << std::endl;
    std::cout << ui::node_update_reason::enabled << std::endl;
    std::cout << ui::node_update_reason::children << std::endl;
    std::cout << ui::node_update_reason::batch << std::endl;
    std::cout << ui::node_update_reason::count << std::endl;
}

@end
