//
//  yas_ui_renderer_tests.mm
//

#import <XCTest/XCTest.h>
#import <iostream>
#import "yas_objc_ptr.h"
#import "yas_observing.h"
#import "yas_test_metal_view_controller.h"
#import "yas_ui.h"

using namespace yas;

@interface yas_ui_renderer_tests : XCTestCase

@end

@implementation yas_ui_renderer_tests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [[YASTestMetalViewController sharedViewController] setRenderable:nullptr];
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
    XCTAssertTrue(renderer.detector());

    XCTAssertEqual(renderer.system_type(), ui::system_type::none);
    XCTAssertFalse(renderer.metal_system());
}

- (void)test_const_getter {
    ui::renderer const renderer;

    XCTAssertTrue(renderer.root_node());
    XCTAssertTrue(renderer.detector());
    XCTAssertFalse(renderer.metal_system());
}

- (void)test_create_null {
    ui::renderer renderer{nullptr};

    XCTAssertFalse(renderer);
}

- (void)test_metal_system {
    auto device = make_objc_ptr(MTLCreateSystemDefaultDevice());
    if (!device) {
        std::cout << "skip : " << __PRETTY_FUNCTION__ << std::endl;
        return;
    }

    ui::renderer renderer{ui::metal_system{device.object()}};

    XCTAssertEqual(renderer.system_type(), ui::system_type::metal);
    XCTAssertTrue(renderer.metal_system());
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

- (void)test_view_configure {
    auto device = make_objc_ptr(MTLCreateSystemDefaultDevice());
    if (!device) {
        std::cout << "skip : " << __PRETTY_FUNCTION__ << std::endl;
        return;
    }

    auto view = [YASTestMetalViewController sharedViewController].metalView;
    [view.window setFrame:CGRectMake(0, 0, 256, 128) display:YES];

    ui::renderer renderer{ui::metal_system{device.object()}};

    XCTAssertEqual(renderer.view_size(), (ui::uint_size{0, 0}));
    XCTAssertEqual(renderer.drawable_size(), (ui::uint_size{0, 0}));

    renderer.view_renderable().configure(view);

    double const scale_factor = renderer.scale_factor();
    XCTAssertEqual(view.sampleCount, 4);
    XCTAssertEqual(renderer.view_size(), (ui::uint_size{256, 128}));
    XCTAssertEqual(renderer.drawable_size(), (ui::uint_size{static_cast<uint32_t>(256 * scale_factor),
                                                            static_cast<uint32_t>(128 * scale_factor)}));
}

@end
