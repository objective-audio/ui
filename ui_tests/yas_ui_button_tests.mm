//
//  yas_ui_button_tests.mm
//

#import <XCTest/XCTest.h>
#import <iostream>
#import <sstream>
#import "yas_test_metal_view_controller.h"
#import "yas_ui.h"

using namespace yas;

@interface yas_ui_button_tests : XCTestCase

@end

@implementation yas_ui_button_tests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [[YASTestMetalViewController sharedViewController] setRenderable:nullptr];
    [super tearDown];
}

- (void)test_initial {
    ui::button button{{.origin = {0.0f, 1.0f}, .size = {2.0f, 3.0f}}};

    XCTAssertTrue(button);
    XCTAssertTrue(button.rect_plane());
    XCTAssertEqual(button.state_index(), 0);
    XCTAssertEqual(button.state_count(), 1);
}

- (void)test_initial_with_state_count {
    ui::button button{{.origin = {0.0f, 1.0f}, .size = {2.0f, 3.0f}}, 3};
    
    XCTAssertEqual(button.state_count(), 3);
}

- (void)test_create_with_null {
    ui::button button{nullptr};

    XCTAssertFalse(button);
}

- (void)test_state_index {
    ui::button button{{.origin = {0.0f, 1.0f}, .size = {2.0f, 3.0f}}, 2};
    
    XCTAssertNoThrow(button.set_state_index(1));
    XCTAssertEqual(button.state_index(), 1);
    
    XCTAssertThrows(button.set_state_index(2));
}

- (void)test_method_changed {
    auto device = make_objc_ptr(MTLCreateSystemDefaultDevice());
    if (!device) {
        std::cout << "skip : " << __PRETTY_FUNCTION__ << std::endl;
        return;
    }

    ui::metal_system metal_system{device.object()};
    ui::renderer renderer{metal_system};
    [[YASTestMetalViewController sharedViewController].view.window setFrame:CGRectMake(0, 0, 2, 2) display:YES];
    [[YASTestMetalViewController sharedViewController] setRenderable:renderer.view_renderable()];

    XCTestExpectation *expectation = [self expectationWithDescription:@"pre_render"];

    ui::action pre_render_action;
    pre_render_action.set_time_updater([expectation, self, &metal_system, count = int{0}](auto const &) mutable {
        [expectation fulfill];
        return true;
    });
    renderer.insert_action(pre_render_action);

    ui::button button{{.origin = {-0.5f, -0.5f}, .size = {1.0f, 1.0f}}};
    renderer.root_node().push_back_sub_node(button.rect_plane().node());

    std::vector<ui::button::method> observed_methods;

    auto observer = button.subject().make_wild_card_observer(
        [&observed_methods](auto const &context) { observed_methods.push_back(context.key); });

    [self waitForExpectationsWithTimeout:1.0 handler:NULL];

    ui::event_manager &event_manager = renderer.event_manager();
    event_manager.inputtable().input_touch_event(ui::event_phase::began, ui::touch_event{1, {0.0f, 0.0f}});

    XCTAssertEqual(observed_methods.size(), 1);
    XCTAssertEqual(observed_methods.back(), ui::button::method::began);

    event_manager.inputtable().input_touch_event(ui::event_phase::changed, ui::touch_event{1, {0.1f, 0.0f}});

    XCTAssertEqual(observed_methods.size(), 1);

    event_manager.inputtable().input_touch_event(ui::event_phase::canceled, ui::touch_event{1, {0.1f, 0.0f}});

    XCTAssertEqual(observed_methods.size(), 2);
    XCTAssertEqual(observed_methods.back(), ui::button::method::canceled);

    event_manager.inputtable().input_touch_event(ui::event_phase::began, ui::touch_event{2, {0.0f, 0.0f}});
    event_manager.inputtable().input_touch_event(ui::event_phase::changed, ui::touch_event{2, {1.0f, 1.0f}});

    XCTAssertEqual(observed_methods.size(), 4);
    XCTAssertEqual(observed_methods.back(), ui::button::method::leaved);

    event_manager.inputtable().input_touch_event(ui::event_phase::changed, ui::touch_event{2, {0.0f, 0.0f}});

    XCTAssertEqual(observed_methods.size(), 5);
    XCTAssertEqual(observed_methods.back(), ui::button::method::entered);

    event_manager.inputtable().input_touch_event(ui::event_phase::ended, ui::touch_event{2, {0.0f, 0.0f}});

    XCTAssertEqual(observed_methods.size(), 6);
    XCTAssertEqual(observed_methods.back(), ui::button::method::ended);
}

- (void)test_state_index_to_rect_index {
    XCTAssertEqual(to_rect_index(0, false), 0);
    XCTAssertEqual(to_rect_index(0, true), 1);
    XCTAssertEqual(to_rect_index(1, false), 2);
    XCTAssertEqual(to_rect_index(1, true), 3);
}

- (void)test_method_to_string {
    XCTAssertEqual(to_string(ui::button::method::began), "began");
    XCTAssertEqual(to_string(ui::button::method::entered), "entered");
    XCTAssertEqual(to_string(ui::button::method::leaved), "leaved");
    XCTAssertEqual(to_string(ui::button::method::ended), "ended");
    XCTAssertEqual(to_string(ui::button::method::canceled), "canceled");
}

- (void)test_method_ostream {
    auto const methods = {ui::button::method::began, ui::button::method::entered, ui::button::method::leaved,
                          ui::button::method::ended, ui::button::method::canceled};

    for (auto const &method : methods) {
        std::ostringstream stream;
        stream << method;
        XCTAssertEqual(stream.str(), to_string(method));
    }
}

@end
