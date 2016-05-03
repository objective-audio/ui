//
//  yas_ui_node_tests.mm
//

#import <XCTest/XCTest.h>
#import <iostream>
#import "yas_objc_ptr.h"
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

    XCTAssertEqual(node.position().value().x, 0.0f);
    XCTAssertEqual(node.position().value().y, 0.0f);
    XCTAssertEqual(node.angle().value(), 0.0f);
    XCTAssertEqual(node.scale().value().width, 1.0f);
    XCTAssertEqual(node.scale().value().height, 1.0f);

    XCTAssertEqual(node.color().value().red, 1.0f);
    XCTAssertEqual(node.color().value().green, 1.0f);
    XCTAssertEqual(node.color().value().blue, 1.0f);
    XCTAssertEqual(node.alpha().value(), 1.0f);

    XCTAssertFalse(node.mesh().value());
    XCTAssertFalse(node.collider().value());

    XCTAssertEqual(node.children().size(), 0);
    XCTAssertFalse(node.parent());
    XCTAssertFalse(node.renderer());

    XCTAssertTrue(node.enabled().value());

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

    node.position().set_value({1.0f, 2.0f});
    node.angle().set_value(3.0f);
    node.scale().set_value({4.0f, 5.0f});
    node.color().set_value({0.1f, 0.2f, 0.3f});
    node.alpha().set_value(0.4f);

    node.enabled().set_value(true);

    XCTAssertEqual(node.position().value().x, 1.0f);
    XCTAssertEqual(node.position().value().y, 2.0f);
    XCTAssertEqual(node.angle().value(), 3.0f);
    XCTAssertEqual(node.scale().value().width, 4.0f);
    XCTAssertEqual(node.scale().value().height, 5.0f);
    XCTAssertEqual(node.color().value().red, 0.1f);
    XCTAssertEqual(node.color().value().green, 0.2f);
    XCTAssertEqual(node.color().value().blue, 0.3f);
    XCTAssertEqual(node.alpha().value(), 0.4f);

    node.mesh().set_value(mesh);
    node.collider().set_value(collider);

    XCTAssertEqual(node.mesh(), mesh);
    XCTAssertEqual(node.collider(), collider);

    XCTAssertTrue(node.enabled().value());
}

- (void)set_color_to_mesh {
    ui::node node;
    ui::mesh mesh;

    XCTAssertEqual(mesh.color()[0], 1.0f);
    XCTAssertEqual(mesh.color()[1], 1.0f);
    XCTAssertEqual(mesh.color()[2], 1.0f);
    XCTAssertEqual(mesh.color()[3], 1.0f);

    node.color().set_value({0.25f, 0.5f, 0.75f});
    node.alpha().set_value(0.125f);

    node.mesh().set_value(mesh);

    XCTAssertEqual(mesh.color()[0], 0.25f);
    XCTAssertEqual(mesh.color()[1], 0.5f);
    XCTAssertEqual(mesh.color()[2], 0.75f);
    XCTAssertEqual(mesh.color()[3], 0.125f);

    node.color().set_value({0.1f, 0.2f, 0.3f});
    node.alpha().set_value(0.4f);

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

    parent_node.add_sub_node(sub_node1);

    XCTAssertEqual(parent_node.children().size(), 1);
    XCTAssertTrue(sub_node1.parent());

    parent_node.add_sub_node(sub_node2);

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

- (void)test_renderable_node {
    id<MTLDevice> device = nil;

    ui::node node;
    ui::node_renderer renderer{device};

    auto renderable = node.renderable();

    XCTAssertFalse(renderable.renderer());

    renderable.set_renderer(renderer);

    XCTAssertTrue(renderable.renderer());
    XCTAssertEqual(renderable.renderer(), renderer);
}

@end
