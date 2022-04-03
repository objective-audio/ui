//
//  yas_ui_button_tests.mm
//

#import <XCTest/XCTest.h>
#import <ui/ui.h>
#import <iostream>
#import <sstream>
#import "yas_test_metal_view_controller.h"
#import "yas_ui_view_look_stubs.h"

using namespace yas;
using namespace yas::ui;

namespace yas::ui::test {
struct renderer_observer_stub final : renderer_observable, renderer_for_view {
    void view_render() override {
    }

    observing::endable observe_will_render(std::function<void(std::nullptr_t const &)> &&) override {
        return observing::endable{};
    }

    observing::endable observe_did_render(std::function<void(std::nullptr_t const &)> &&) override {
        return observing::endable{};
    }
};
}

@interface yas_ui_button_tests : XCTestCase

@end

@implementation yas_ui_button_tests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [[YASTestMetalViewController sharedViewController] configure_with_metal_system:nullptr
                                                                          renderer:nullptr
                                                                     event_manager:nullptr];
    [super tearDown];
}

- (void)test_initial {
    auto button = button::make_shared({.origin = {0.0f, 1.0f}, .size = {2.0f, 3.0f}}, ui::event_manager::make_shared(),
                                      ui::detector::make_shared(), std::make_shared<test::renderer_observer_stub>());

    XCTAssertTrue(button);
    XCTAssertTrue(button->rect_plane());
    XCTAssertEqual(button->state_index(), 0);
    XCTAssertEqual(button->state_count(), 1);
}

- (void)test_initial_with_state_count {
    auto button = button::make_shared({.origin = {0.0f, 1.0f}, .size = {2.0f, 3.0f}}, ui::event_manager::make_shared(),
                                      ui::detector::make_shared(), std::make_shared<test::renderer_observer_stub>(), 3);

    XCTAssertEqual(button->state_count(), 3);
}

- (void)test_state_index {
    auto button = button::make_shared({.origin = {0.0f, 1.0f}, .size = {2.0f, 3.0f}}, ui::event_manager::make_shared(),
                                      ui::detector::make_shared(), std::make_shared<test::renderer_observer_stub>(), 2);

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

    auto *const view = [YASTestMetalViewController sharedViewController].metalView;
    auto const metal_system = metal_system::make_shared(device.object(), view);
    auto const view_look = ui::view_look::make_shared();
    auto const root_node = ui::node::make_shared();
    auto const detector = ui::detector::make_shared();
    auto const event_manager = ui::event_manager::make_shared();
    std::shared_ptr<event_manager_for_view> const view_event_manager = event_manager;
    auto const action_manager = ui::action_manager::make_shared();
    auto const renderer = renderer::make_shared(metal_system, view_look, root_node, detector, action_manager);
    [[YASTestMetalViewController sharedViewController].view.window setFrame:CGRectMake(0, 0, 2, 2) display:YES];
    [[YASTestMetalViewController sharedViewController] configure_with_metal_system:metal_system
                                                                          renderer:renderer
                                                                     event_manager:nullptr];

    XCTestExpectation *expectation = [self expectationWithDescription:@"pre_render"];

    auto pre_render_action = action::make_shared(
        {.time_updater = [expectation, self, &metal_system, count = int{0}](auto const &, auto const &) mutable {
            [expectation fulfill];
            return true;
        }});

    action_manager->insert_action(pre_render_action);

    auto button =
        button::make_shared({.origin = {-0.5f, -0.5f}, .size = {1.0f, 1.0f}}, event_manager, detector, renderer);
    root_node->add_sub_node(button->rect_plane()->node());

    std::vector<button::phase> observed_methods;

    auto canceller =
        button->observe([&observed_methods](auto const &context) { observed_methods.push_back(context.phase); });

    [self waitForExpectationsWithTimeout:1.0 handler:NULL];

    view_event_manager->input_touch_event(event_phase::began,
                                          touch_event{{.kind = touch_kind::touch, .identifier = 1}, {0.0f, 0.0f}, 0});

    XCTAssertEqual(observed_methods.size(), 1);
    XCTAssertEqual(observed_methods.back(), button::phase::began);

    view_event_manager->input_touch_event(event_phase::changed,
                                          touch_event{{.kind = touch_kind::touch, .identifier = 1}, {0.1f, 0.0f}, 0});

    XCTAssertEqual(observed_methods.size(), 2);
    XCTAssertEqual(observed_methods.back(), button::phase::moved);

    view_event_manager->input_touch_event(event_phase::canceled,
                                          touch_event{{.kind = touch_kind::touch, .identifier = 1}, {0.1f, 0.0f}, 0});

    XCTAssertEqual(observed_methods.size(), 3);
    XCTAssertEqual(observed_methods.back(), button::phase::canceled);

    view_event_manager->input_touch_event(event_phase::began,
                                          touch_event{{.kind = touch_kind::touch, .identifier = 2}, {0.0f, 0.0f}, 0});
    view_event_manager->input_touch_event(event_phase::changed,
                                          touch_event{{.kind = touch_kind::touch, .identifier = 2}, {1.0f, 1.0f}, 0});

    XCTAssertEqual(observed_methods.size(), 5);
    XCTAssertEqual(observed_methods.back(), button::phase::leaved);

    view_event_manager->input_touch_event(event_phase::changed,
                                          touch_event{{.kind = touch_kind::touch, .identifier = 2}, {0.0f, 0.0f}, 0});

    XCTAssertEqual(observed_methods.size(), 6);
    XCTAssertEqual(observed_methods.back(), button::phase::entered);

    view_event_manager->input_touch_event(event_phase::ended,
                                          touch_event{{.kind = touch_kind::touch, .identifier = 2}, {0.0f, 0.0f}, 0});

    XCTAssertEqual(observed_methods.size(), 7);
    XCTAssertEqual(observed_methods.back(), button::phase::ended);
}

- (void)test_set_texture {
    auto const button =
        button::make_shared({.origin = {0.0f, 1.0f}, .size = {2.0f, 3.0f}}, ui::event_manager::make_shared(),
                            ui::detector::make_shared(), std::make_shared<test::renderer_observer_stub>());

    XCTAssertFalse(button->rect_plane()->node()->mesh()->texture());

    auto const view_look = view_look_scale_factor_stub::make_shared(1.0);
    auto const texture = texture::make_shared({.point_size = {8, 8}}, view_look);

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
    XCTAssertEqual(to_string(button::phase::began), "began");
    XCTAssertEqual(to_string(button::phase::entered), "entered");
    XCTAssertEqual(to_string(button::phase::moved), "moved");
    XCTAssertEqual(to_string(button::phase::leaved), "leaved");
    XCTAssertEqual(to_string(button::phase::ended), "ended");
    XCTAssertEqual(to_string(button::phase::canceled), "canceled");
}

- (void)test_method_ostream {
    auto const methods = {button::phase::began, button::phase::entered, button::phase::leaved, button::phase::ended,
                          button::phase::canceled};

    for (auto const &method : methods) {
        std::ostringstream stream;
        stream << method;
        XCTAssertEqual(stream.str(), to_string(method));
    }
}

@end
