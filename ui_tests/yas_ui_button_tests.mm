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

- (void)test_create {
    ui::button button{{0.0f, 1.0f, 2.0f, 3.0f}};

    XCTAssertTrue(button);
    XCTAssertTrue(button.rect_plane());
}

- (void)test_create_null {
    ui::button button{nullptr};

    XCTAssertFalse(button);
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

    ui::button button{{-0.5f, -0.5f, 1.0f, 1.0f}};
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

- (void)test_state_to_index {
    XCTAssertEqual(to_index(ui::button::states_t{}), 0);
    XCTAssertEqual(to_index({ui::button::state::press}), 1);
    XCTAssertEqual(to_index({ui::button::state::toggle}), 2);
    XCTAssertEqual(to_index({ui::button::state::toggle, ui::button::state::press}), 3);
}

- (void)test_method_to_string {
    XCTAssertEqual(to_string(ui::button::method::began), "began");
    XCTAssertEqual(to_string(ui::button::method::entered), "entered");
    XCTAssertEqual(to_string(ui::button::method::leaved), "leaved");
    XCTAssertEqual(to_string(ui::button::method::ended), "ended");
    XCTAssertEqual(to_string(ui::button::method::canceled), "canceled");
}

- (void)test_state_to_string {
    XCTAssertEqual(to_string(ui::button::state::toggle), "toggle");
    XCTAssertEqual(to_string(ui::button::state::press), "press");
    XCTAssertEqual(to_string(ui::button::state::count), "count");
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

- (void)test_state_ostream {
    auto const states = {ui::button::state::toggle, ui::button::state::press, ui::button::state::count};

    for (auto const &state : states) {
        std::ostringstream stream;
        stream << state;
        XCTAssertEqual(stream.str(), to_string(state));
    }
}

@end
