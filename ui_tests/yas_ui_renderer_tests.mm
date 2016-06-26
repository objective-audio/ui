//
//  yas_ui_renderer_tests.mm
//

#import <XCTest/XCTest.h>
#import "yas_observing.h"
#import "yas_ui_action.h"
#import "yas_ui_batch.h"
#import "yas_ui_collision_detector.h"
#import "yas_ui_event.h"
#import "yas_ui_metal_system.h"
#import "yas_ui_node.h"
#import "yas_ui_renderer.h"
#import "yas_ui_types.h"

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
    ui::renderer renderer;

    XCTAssertFalse(renderer.metal_system());

    XCTAssertTrue(renderer.root_node());
    XCTAssertEqual(renderer.actions().size(), 0);

    XCTAssertEqual(renderer.view_size(), (ui::uint_size{0, 0}));
    XCTAssertEqual(renderer.drawable_size(), (ui::uint_size{0, 0}));
    XCTAssertEqual(renderer.scale_factor(), 0.0);

    XCTAssertTrue(renderer.view_renderable());
    XCTAssertTrue(renderer.event_manager());
    XCTAssertTrue(renderer.collision_detector());
}

- (void)test_const_getter {
    ui::renderer const renderer;

    XCTAssertTrue(renderer.root_node());
    XCTAssertTrue(renderer.collision_detector());
}

- (void)test_create_null {
    ui::renderer renderer{nullptr};

    XCTAssertFalse(renderer);
}

- (void)test_action {
    ui::renderer renderer;

    ui::node target1;
    ui::node target2;
    ui::action action1;
    ui::action action2;
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
