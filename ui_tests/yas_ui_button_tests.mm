//
//  yas_ui_button_tests.mm
//

#import <XCTest/XCTest.h>
#import <ui/ui.h>
#import <iostream>
#import <sstream>
#import "yas_test_metal_view_controller.h"

using namespace yas;
using namespace yas::ui;

@interface yas_ui_button_tests : XCTestCase

@end

@implementation yas_ui_button_tests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [[YASTestMetalViewController sharedViewController] set_renderer:nullptr];
    [[YASTestMetalViewController sharedViewController] set_event_manager:nullptr];
    [super tearDown];
}

- (void)test_initial {
    auto button = button::make_shared({.origin = {0.0f, 1.0f}, .size = {2.0f, 3.0f}}, ui::event_manager::make_shared(),
                                      ui::detector::make_shared());

    XCTAssertTrue(button);
    XCTAssertTrue(button->rect_plane());
    XCTAssertEqual(button->state_index(), 0);
    XCTAssertEqual(button->state_count(), 1);
}

- (void)test_initial_with_state_count {
    auto button = button::make_shared({.origin = {0.0f, 1.0f}, .size = {2.0f, 3.0f}}, 3,
                                      ui::event_manager::make_shared(), ui::detector::make_shared());

    XCTAssertEqual(button->state_count(), 3);
}

- (void)test_state_index {
    auto button = button::make_shared({.origin = {0.0f, 1.0f}, .size = {2.0f, 3.0f}}, 2,
                                      ui::event_manager::make_shared(), ui::detector::make_shared());

    XCTAssertNoThrow(button->set_state_index(1));
    XCTAssertEqual(button->state_index(), 1);

    XCTAssertThrows(button->set_state_index(2));
}

- (void)test_method_changed {
    auto device = objc_ptr_with_move_object(MTLCreateSystemDefaultDevice());
    if (!device) {
        std::cout << "skip : " << __PRETTY_FUNCTION__ << std::endl;
        return;
    }

    auto const metal_system = metal_system::make_shared(device.object());
    auto const event_manager = ui::event_manager::make_shared();
    std::shared_ptr<metal_view_event_manager_interface> const view_event_manager = event_manager;
    auto const action_manager = ui::action_manager::make_shared();
    auto const renderer = renderer::make_shared(metal_system, action_manager);
    [[YASTestMetalViewController sharedViewController].view.window setFrame:CGRectMake(0, 0, 2, 2) display:YES];
    [[YASTestMetalViewController sharedViewController] set_renderer:renderer];
    [[YASTestMetalViewController sharedViewController] set_event_manager:event_manager];

    XCTestExpectation *expectation = [self expectationWithDescription:@"pre_render"];

    auto pre_render_action = action::make_shared(
        {.time_updater = [expectation, self, &metal_system, count = int{0}](auto const &, auto const &) mutable {
            [expectation fulfill];
            return true;
        }});

    action_manager->insert_action(pre_render_action);

    auto button =
        button::make_shared({.origin = {-0.5f, -0.5f}, .size = {1.0f, 1.0f}}, event_manager, renderer->detector());
    renderer->root_node()->add_sub_node(button->rect_plane()->node());

    std::vector<button::method> observed_methods;

    auto canceller =
        button->observe([&observed_methods](auto const &context) { observed_methods.push_back(context.method); });

    [self waitForExpectationsWithTimeout:1.0 handler:NULL];

    view_event_manager->input_touch_event(event_phase::began, touch_event{1, {0.0f, 0.0f}, 0});

    XCTAssertEqual(observed_methods.size(), 1);
    XCTAssertEqual(observed_methods.back(), button::method::began);

    view_event_manager->input_touch_event(event_phase::changed, touch_event{1, {0.1f, 0.0f}, 0});

    XCTAssertEqual(observed_methods.size(), 2);
    XCTAssertEqual(observed_methods.back(), button::method::moved);

    view_event_manager->input_touch_event(event_phase::canceled, touch_event{1, {0.1f, 0.0f}, 0});

    XCTAssertEqual(observed_methods.size(), 3);
    XCTAssertEqual(observed_methods.back(), button::method::canceled);

    view_event_manager->input_touch_event(event_phase::began, touch_event{2, {0.0f, 0.0f}, 0});
    view_event_manager->input_touch_event(event_phase::changed, touch_event{2, {1.0f, 1.0f}, 0});

    XCTAssertEqual(observed_methods.size(), 5);
    XCTAssertEqual(observed_methods.back(), button::method::leaved);

    view_event_manager->input_touch_event(event_phase::changed, touch_event{2, {0.0f, 0.0f}, 0});

    XCTAssertEqual(observed_methods.size(), 6);
    XCTAssertEqual(observed_methods.back(), button::method::entered);

    view_event_manager->input_touch_event(event_phase::ended, touch_event{2, {0.0f, 0.0f}, 0});

    XCTAssertEqual(observed_methods.size(), 7);
    XCTAssertEqual(observed_methods.back(), button::method::ended);
}

- (void)test_set_texture {
    auto button = button::make_shared({.origin = {0.0f, 1.0f}, .size = {2.0f, 3.0f}}, ui::event_manager::make_shared(),
                                      ui::detector::make_shared());

    XCTAssertFalse(button->rect_plane()->node()->mesh()->texture());

    auto texture = texture::make_shared({.point_size = {8, 8}});

    button->set_texture(texture);

    XCTAssertTrue(button->rect_plane()->node()->mesh()->texture());
    XCTAssertEqual(button->texture(), texture);
}

- (void)test_state_index_to_rect_index {
    XCTAssertEqual(to_rect_index(0, false), 0);
    XCTAssertEqual(to_rect_index(0, true), 1);
    XCTAssertEqual(to_rect_index(1, false), 2);
    XCTAssertEqual(to_rect_index(1, true), 3);
}

- (void)test_method_to_string {
    XCTAssertEqual(to_string(button::method::began), "began");
    XCTAssertEqual(to_string(button::method::entered), "entered");
    XCTAssertEqual(to_string(button::method::moved), "moved");
    XCTAssertEqual(to_string(button::method::leaved), "leaved");
    XCTAssertEqual(to_string(button::method::ended), "ended");
    XCTAssertEqual(to_string(button::method::canceled), "canceled");
}

- (void)test_method_ostream {
    auto const methods = {button::method::began, button::method::entered, button::method::leaved, button::method::ended,
                          button::method::canceled};

    for (auto const &method : methods) {
        std::ostringstream stream;
        stream << method;
        XCTAssertEqual(stream.str(), to_string(method));
    }
}

@end
