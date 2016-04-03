//
//  yas_ui_action_tests.mm
//

#import <XCTest/XCTest.h>
#import <unordered_set>
#import "yas_ui_action.h"
#import "yas_ui_node.h"

using namespace std::chrono_literals;
using namespace yas;

@interface yas_ui_action_tests : XCTestCase

@end

@implementation yas_ui_action_tests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)test_create {
    ui::action action;

    XCTAssertFalse(action.target());
    XCTAssertFalse(action.update_handler());
}

- (void)test_create_null {
    ui::action action{nullptr};
    ui::translate_action translate_action{nullptr};
    ui::rotate_action rotate_action{nullptr};
    ui::scale_action scale_action{nullptr};
    ui::color_action color_action{nullptr};

    XCTAssertFalse(action);
    XCTAssertFalse(translate_action);
    XCTAssertFalse(rotate_action);
    XCTAssertFalse(scale_action);
    XCTAssertFalse(color_action);
}

- (void)test_create_one_shot_action {
    ui::translate_action action;

    XCTAssertFalse(action.target());
    XCTAssertEqual(action.duration(), 0.3);
    XCTAssertFalse(action.value_transformer());

    auto const &start_time = action.start_time();
    auto const now = std::chrono::system_clock::now();

    XCTAssertTrue(start_time <= now);
    XCTAssertTrue((now + -100ms) < start_time);

    XCTAssertTrue(action.updatable());
}

- (void)test_finished_handler {
    ui::translate_action action;
    auto updatable_action = action.updatable();
    auto const start_time = std::chrono::system_clock::now();

    action.set_duration(1.0);
    action.set_start_time(start_time);

    XCTAssertFalse(updatable_action.update(start_time + 999ms));
    XCTAssertTrue(updatable_action.update(start_time + 1000ms));
}

- (void)test_set_variables_to_action {
    ui::translate_action action;
    ui::node target;
    auto const time = std::chrono::system_clock::now();

    action.set_target(target);
    action.set_duration(10.0);
    action.set_value_transformer(ui::ease_out_transformer());
    action.set_completion_handler([]() {});
    action.set_start_time(time);

    XCTAssertEqual(action.target(), target);
    XCTAssertEqual(action.duration(), 10.0);
    XCTAssertTrue(action.value_transformer());
    XCTAssertTrue(action.completion_handler());
    XCTAssertEqual(action.start_time(), time);
}

- (void)test_set_variables_to_translate_action {
    ui::translate_action action;

    action.set_start_position({0.5, -1.5});
    action.set_end_position({-10.0, 20.0});

    XCTAssertEqual(action.start_position().x, 0.5);
    XCTAssertEqual(action.start_position().y, -1.5);
    XCTAssertEqual(action.end_position().x, -10.0);
    XCTAssertEqual(action.end_position().y, 20.0);
}

- (void)test_set_variables_to_rotate_action {
    ui::rotate_action action;

    action.set_start_angle(1.0f);
    action.set_end_angle(2.0f);

    XCTAssertEqual(action.start_angle(), 1.0f);
    XCTAssertEqual(action.end_angle(), 2.0f);
}

- (void)test_set_variables_to_scale_action {
    ui::scale_action action;

    action.set_start_scale({3.0f, 5.0f});
    action.set_end_scale({6.0f, 10.0f});

    XCTAssertEqual(action.start_scale().x, 3.0f);
    XCTAssertEqual(action.start_scale().y, 5.0f);
    XCTAssertEqual(action.end_scale().x, 6.0f);
    XCTAssertEqual(action.end_scale().y, 10.0f);
}

- (void)test_set_variables_to_color_action {
    ui::color_action action;

    action.set_start_color({0.1f, 0.2f, 0.3f, 0.4f});
    action.set_end_color({0.9f, 0.8f, 0.7f, 0.6f});

    XCTAssertEqual(action.start_color()[0], 0.1f);
    XCTAssertEqual(action.start_color()[1], 0.2f);
    XCTAssertEqual(action.start_color()[2], 0.3f);
    XCTAssertEqual(action.start_color()[3], 0.4f);
    XCTAssertEqual(action.end_color()[0], 0.9f);
    XCTAssertEqual(action.end_color()[1], 0.8f);
    XCTAssertEqual(action.end_color()[2], 0.7f);
    XCTAssertEqual(action.end_color()[3], 0.6f);
}

- (void)test_update_translate_action {
    ui::translate_action action;
    ui::node target;
    auto updatable = action.updatable();

    action.set_target(target);
    action.set_start_position({0.0f, -1.0f});
    action.set_end_position({1.0f, 1.0f});
    action.set_duration(1.0);

    auto now = std::chrono::system_clock::now();

    action.set_start_time(now);

    updatable.update(now);

    XCTAssertEqual(target.position().x, 0.0f);
    XCTAssertEqual(target.position().y, -1.0f);

    updatable.update(now + 500ms);

    XCTAssertEqual(target.position().x, 0.5f);
    XCTAssertEqual(target.position().y, 0.0f);

    updatable.update(now + 1s);

    XCTAssertEqual(target.position().x, 1.0f);
    XCTAssertEqual(target.position().y, 1.0f);
}

- (void)test_update_rotate_action {
    ui::rotate_action action;
    ui::node target;
    auto updatable = action.updatable();

    action.set_target(target);
    action.set_start_angle(0.0f);
    action.set_end_angle(360.0f);
    action.set_shortest(false);
    action.set_duration(1.0);

    auto now = std::chrono::system_clock::now();

    action.set_start_time(now);

    updatable.update(now);

    XCTAssertEqual(target.angle(), 0.0f);

    updatable.update(now + 500ms);

    XCTAssertEqual(target.angle(), 180.0f);

    updatable.update(now + 1s);

    XCTAssertEqual(target.angle(), 360.0f);
}

- (void)test_update_rotate_action_shortest_1 {
    ui::rotate_action action;
    ui::node target;
    auto updatable = action.updatable();

    action.set_target(target);
    action.set_start_angle(0.0f);
    action.set_end_angle(270.0f);
    action.set_shortest(true);
    action.set_duration(1.0);

    auto now = std::chrono::system_clock::now();

    action.set_start_time(now);

    updatable.update(now);

    XCTAssertEqual(target.angle(), 360.0f);

    updatable.update(now + 500ms);

    XCTAssertEqual(target.angle(), 315.0f);

    updatable.update(now + 1s);

    XCTAssertEqual(target.angle(), 270.0f);
}

- (void)test_update_rotate_action_shortest_2 {
    ui::rotate_action action;
    ui::node target;
    auto updatable = action.updatable();

    action.set_target(target);
    action.set_start_angle(-180.0f);
    action.set_end_angle(90.0f);
    action.set_shortest(true);
    action.set_duration(1.0);

    auto now = std::chrono::system_clock::now();

    action.set_start_time(now);

    updatable.update(now);

    XCTAssertEqual(target.angle(), 180.0f);

    updatable.update(now + 500ms);

    XCTAssertEqual(target.angle(), 135.0f);

    updatable.update(now + 1s);

    XCTAssertEqual(target.angle(), 90.0f);
}

- (void)test_update_scale_action {
    ui::scale_action action;
    ui::node target;
    auto updatable = action.updatable();

    action.set_target(target);
    action.set_start_scale({0.0f, -1.0f});
    action.set_end_scale({1.0f, 1.0f});
    action.set_duration(1.0);

    auto now = std::chrono::system_clock::now();

    action.set_start_time(now);

    updatable.update(now);

    XCTAssertEqual(target.scale().x, 0.0f);
    XCTAssertEqual(target.scale().y, -1.0f);

    updatable.update(now + 500ms);

    XCTAssertEqual(target.scale().x, 0.5f);
    XCTAssertEqual(target.scale().y, 0.0f);

    updatable.update(now + 1s);

    XCTAssertEqual(target.scale().x, 1.0f);
    XCTAssertEqual(target.scale().y, 1.0f);
}

- (void)test_update_color_action {
    ui::color_action action;
    ui::mesh mesh{0, 0, false};
    ui::node target;
    target.set_mesh(mesh);
    auto updatable = action.updatable();

    action.set_target(target);
    action.set_start_color({0.0f, 0.25f, 0.5f, 1.0f});
    action.set_end_color({1.0f, 0.75f, 0.5f, 0.0f});
    action.set_duration(1.0);

    auto now = std::chrono::system_clock::now();

    action.set_start_time(now);

    updatable.update(now);

    XCTAssertEqual(target.color()[0], 0.0f);
    XCTAssertEqual(target.color()[1], 0.25f);
    XCTAssertEqual(target.color()[2], 0.5f);
    XCTAssertEqual(target.color()[3], 1.0f);

    updatable.update(now + 500ms);

    XCTAssertEqual(target.color()[0], 0.5f);
    XCTAssertEqual(target.color()[1], 0.5f);
    XCTAssertEqual(target.color()[2], 0.5f);
    XCTAssertEqual(target.color()[3], 0.5f);

    updatable.update(now + 1s);

    XCTAssertEqual(target.color()[0], 1.0f);
    XCTAssertEqual(target.color()[1], 0.75f);
    XCTAssertEqual(target.color()[2], 0.5f);
    XCTAssertEqual(target.color()[3], 0.0f);
}

- (void)test_completion_handler {
    ui::rotate_action action;
    auto updatable = action.updatable();

    bool completed = false;
    action.set_completion_handler([&completed]() { completed = true; });
    action.set_duration(1.0);

    auto now = std::chrono::system_clock::now();

    action.set_start_time(now);

    updatable.update(now);

    XCTAssertFalse(completed);

    updatable.update(now + 500ms);

    XCTAssertFalse(completed);

    updatable.update(now + 1s);

    XCTAssertTrue(completed);
}

- (void)test_ease_in_transformer {
    auto const &transformer = ui::ease_in_transformer();

    XCTAssertEqual(transformer(0.0f), 0.0f);
    XCTAssertLessThan(transformer(0.25f), 0.25f);
    XCTAssertLessThan(transformer(0.5f), 0.5f);
    XCTAssertLessThan(transformer(0.75f), 0.75f);
    XCTAssertEqual(transformer(1.0f), 1.0f);
}

- (void)test_ease_out_transformer {
    auto const &transformer = ui::ease_out_transformer();

    XCTAssertEqual(transformer(0.0f), 0.0f);
    XCTAssertGreaterThan(transformer(0.25f), 0.25f);
    XCTAssertGreaterThan(transformer(0.5f), 0.5f);
    XCTAssertGreaterThan(transformer(0.75f), 0.75f);
    XCTAssertEqual(transformer(1.0f), 1.0f);
}

- (void)test_ease_in_out_transformer {
    auto const &transformer = ui::ease_in_out_transformer();

    XCTAssertEqual(transformer(0.0f), 0.0f);
    XCTAssertLessThan(transformer(0.25f), 0.25f);
    XCTAssertEqual(transformer(0.5f), 0.5f);
    XCTAssertGreaterThan(transformer(0.75f), 0.75f);
    XCTAssertEqual(transformer(1.0f), 1.0f);
}

@end
