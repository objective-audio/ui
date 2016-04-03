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

- (void)test_create_action {
    ui::action action;

    XCTAssertFalse(action.target());
    XCTAssertFalse(action.update_handler());
    XCTAssertFalse(action.completion_handler());

    auto const &start_time = action.start_time();
    auto const now = std::chrono::system_clock::now();

    XCTAssertTrue(start_time <= now);
    XCTAssertTrue((now + -100ms) < start_time);

    XCTAssertTrue(action.updatable());
}

- (void)test_create_action_null {
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

    XCTAssertEqual(action.duration(), 0.3);
    XCTAssertFalse(action.value_transformer());
}

- (void)test_updatable_finished {
    ui::translate_action action;
    auto updatable_action = action.updatable();
    auto const start_time = std::chrono::system_clock::now();

    action.set_duration(1.0);
    action.set_start_time(start_time);

    XCTAssertFalse(updatable_action.update(start_time + 999ms));
    XCTAssertTrue(updatable_action.update(start_time + 1000ms));
}

- (void)test_set_variables_to_action {
    ui::action action;
    ui::node target;
    auto const time = std::chrono::system_clock::now();

    action.set_target(target);
    action.set_start_time(time);
    action.set_update_handler([](auto const &time) { return false; });
    action.set_completion_handler([]() {});

    XCTAssertEqual(action.target(), target);
    XCTAssertEqual(action.start_time(), time);
    XCTAssertTrue(action.update_handler());
    XCTAssertTrue(action.completion_handler());
}

- (void)test_set_variables_to_one_shot_action {
    ui::translate_action action;
    ui::node target;

    action.set_duration(10.0);
    action.set_value_transformer(ui::ease_out_transformer());

    XCTAssertEqual(action.duration(), 10.0);
    XCTAssertTrue(action.value_transformer());
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
    action.set_shortest(true);

    XCTAssertEqual(action.start_angle(), 1.0f);
    XCTAssertEqual(action.end_angle(), 2.0f);
    XCTAssertEqual(action.is_shortest(), true);
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

- (void)test_start_time {
    ui::action action;
    auto updatable = action.updatable();

    auto now = std::chrono::system_clock::now();

    action.set_start_time(now + 1s);

    XCTAssertFalse(updatable.update(now));
    XCTAssertFalse(updatable.update(now + 999ms));
    XCTAssertTrue(updatable.update(now + 1s));
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

- (void)test_create_parallel_action {
    ui::parallel_action parallel_action;

    XCTAssertEqual(parallel_action.actions().size(), 0);
}

- (void)test_parallel_action {
    ui::parallel_action parallel_action;

    auto now = std::chrono::system_clock::now();

    ui::translate_action action1;
    action1.set_start_time(now);
    action1.set_duration(1.0);
    parallel_action.insert_action(std::move(action1));

    ui::rotate_action action2;
    action2.set_start_time(now);
    action2.set_duration(2.0);
    parallel_action.insert_action(std::move(action2));

    ui::scale_action action3;
    action3.set_start_time(now);
    action3.set_duration(3.0);
    parallel_action.insert_action(std::move(action3));

    XCTAssertEqual(parallel_action.actions().size(), 3);

    XCTAssertFalse(parallel_action.updatable().update(now));
    XCTAssertEqual(parallel_action.actions().size(), 3);

    XCTAssertFalse(parallel_action.updatable().update(now + 999ms));
    XCTAssertEqual(parallel_action.actions().size(), 3);

    XCTAssertFalse(parallel_action.updatable().update(now + 1s));
    XCTAssertEqual(parallel_action.actions().size(), 2);

    XCTAssertFalse(parallel_action.updatable().update(now + 1999ms));
    XCTAssertEqual(parallel_action.actions().size(), 2);

    XCTAssertFalse(parallel_action.updatable().update(now + 2s));
    XCTAssertEqual(parallel_action.actions().size(), 1);

    XCTAssertFalse(parallel_action.updatable().update(now + 2999ms));
    XCTAssertEqual(parallel_action.actions().size(), 1);

    XCTAssertTrue(parallel_action.updatable().update(now + 3s));
    XCTAssertEqual(parallel_action.actions().size(), 0);
}

- (void)test_make_sequence {
    ui::action first_action;
    ui::rotate_action rotate_action;
    ui::action end_action;
    ui::scale_action scale_action;

    bool first_completed = false;
    bool rotate_completed = false;
    bool end_completed = false;
    bool scale_completed = false;
    bool sequence_completed = false;

    first_action.set_completion_handler([&first_completed] { first_completed = true; });
    rotate_action.set_duration(1.0);
    rotate_action.set_completion_handler([&rotate_completed] { rotate_completed = true; });
    end_action.set_completion_handler([&end_completed] { end_completed = true; });
    scale_action.set_duration(0.5);
    scale_action.set_completion_handler([&scale_completed] { scale_completed = true; });

    auto now = std::chrono::system_clock::now();

    auto action_sequence = ui::make_action_sequence({first_action, rotate_action, end_action, scale_action}, now + 1s);
    action_sequence.set_completion_handler([&sequence_completed] { sequence_completed = true; });
    auto updatable = action_sequence.updatable();

    XCTAssertFalse(updatable.update(now));

    XCTAssertFalse(first_completed);
    XCTAssertFalse(rotate_completed);
    XCTAssertFalse(end_completed);
    XCTAssertFalse(scale_completed);
    XCTAssertFalse(sequence_completed);

    XCTAssertFalse(updatable.update(now + 999ms));

    XCTAssertFalse(first_completed);
    XCTAssertFalse(rotate_completed);
    XCTAssertFalse(end_completed);
    XCTAssertFalse(scale_completed);
    XCTAssertFalse(sequence_completed);

    XCTAssertFalse(updatable.update(now + 1s));

    XCTAssertTrue(first_completed);
    XCTAssertFalse(rotate_completed);
    XCTAssertFalse(end_completed);
    XCTAssertFalse(scale_completed);
    XCTAssertFalse(sequence_completed);

    XCTAssertFalse(updatable.update(now + 1999ms));

    XCTAssertTrue(first_completed);
    XCTAssertFalse(rotate_completed);
    XCTAssertFalse(end_completed);
    XCTAssertFalse(scale_completed);
    XCTAssertFalse(sequence_completed);

    XCTAssertFalse(updatable.update(now + 2s));

    XCTAssertTrue(first_completed);
    XCTAssertTrue(rotate_completed);
    XCTAssertTrue(end_completed);
    XCTAssertFalse(scale_completed);
    XCTAssertFalse(sequence_completed);

    XCTAssertFalse(updatable.update(now + 2499ms));
    
    XCTAssertTrue(first_completed);
    XCTAssertTrue(rotate_completed);
    XCTAssertTrue(end_completed);
    XCTAssertFalse(scale_completed);
    XCTAssertFalse(sequence_completed);

    XCTAssertTrue(updatable.update(now + 2500ms));
    
    XCTAssertTrue(first_completed);
    XCTAssertTrue(rotate_completed);
    XCTAssertTrue(end_completed);
    XCTAssertTrue(scale_completed);
    XCTAssertTrue(sequence_completed);
}

#pragma mark - transformer

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
