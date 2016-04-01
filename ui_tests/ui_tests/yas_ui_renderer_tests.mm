//
//  yas_ui_renderer_tests.mm
//

#import <XCTest/XCTest.h>
#import "yas_ui_action.h"
#import "yas_ui_node.h"
#import "yas_ui_renderer.h"

using namespace yas;

@interface yas_ui_renderer_tests : XCTestCase

@end

@implementation yas_ui_renderer_tests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)test_create {
    id<MTLDevice> device = nil;
    ui::node_renderer renderer{device};

    XCTAssertTrue(renderer.root_node());
    XCTAssertEqual(renderer.actions().size(), 0);

    XCTAssertTrue(renderer.view_renderable());
}

- (void)test_create_null {
    ui::node_renderer renderer{nullptr};

    XCTAssertFalse(renderer);
}

- (void)test_action {
    id<MTLDevice> device = nil;
    ui::node_renderer renderer{device};

    ui::node target1;
    ui::node target2;
    ui::translate_action action1;
    ui::rotate_action action2;
    action1.set_target(target1);
    action2.set_target(target2);

    renderer.insert_action(action1);

    XCTAssertEqual(renderer.actions().size(), 1);
    XCTAssertEqual(renderer.actions().at(0), action1);

    renderer.insert_action(action2);

    XCTAssertEqual(renderer.actions().size(), 2);

    renderer.erase_action(target1);

    XCTAssertEqual(renderer.actions().size(), 1);
    XCTAssertEqual(renderer.actions().at(0), action2);

    renderer.erase_action(action2);

    XCTAssertEqual(renderer.actions().size(), 0);
}

@end
