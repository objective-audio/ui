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

    XCTAssertEqual(node.position().x, 0.0f);
    XCTAssertEqual(node.position().y, 0.0f);
    XCTAssertEqual(node.angle(), 0.0f);
    XCTAssertEqual(node.scale().x, 1.0f);
    XCTAssertEqual(node.scale().y, 1.0f);

    XCTAssertEqual(node.color()[0], 0.0f);
    XCTAssertEqual(node.color()[1], 0.0f);
    XCTAssertEqual(node.color()[2], 0.0f);
    XCTAssertEqual(node.color()[3], 0.0f);

    XCTAssertFalse(node.mesh());

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

    node.set_position({1.0f, 2.0f});
    node.set_angle(3.0f);
    node.set_scale({4.0f, 5.0f});

    node.set_mesh(mesh);

    node.set_enabled(true);

    XCTAssertEqual(node.position().x, 1.0f);
    XCTAssertEqual(node.position().y, 2.0f);
    XCTAssertEqual(node.angle(), 3.0f);
    XCTAssertEqual(node.scale().x, 4.0f);
    XCTAssertEqual(node.scale().y, 5.0f);

    XCTAssertEqual(node.mesh(), mesh);

    XCTAssertTrue(node.is_enabled());
}

- (void)test_color {
    ui::node node;
    ui::mesh mesh;

    node.set_color({0.1f, 0.2f, 0.3f, 0.4f});

    XCTAssertEqual(node.color()[0], 0.0f);
    XCTAssertEqual(node.color()[1], 0.0f);
    XCTAssertEqual(node.color()[2], 0.0f);
    XCTAssertEqual(node.color()[3], 0.0f);

    node.set_mesh(mesh);
    node.set_color({0.9f, 0.8f, 0.7f, 0.6f});

    XCTAssertEqual(node.color()[0], 0.9f);
    XCTAssertEqual(node.color()[1], 0.8f);
    XCTAssertEqual(node.color()[2], 0.7f);
    XCTAssertEqual(node.color()[3], 0.6f);
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
