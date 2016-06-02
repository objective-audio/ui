//
//  yas_ui_action_tests.mm
//

#import <XCTest/XCTest.h>
#import <unordered_set>
#import "yas_ui_action.h"
#import "yas_ui_mesh.h"
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
    XCTAssertEqual(action.delay(), 0.0);
    XCTAssertFalse(action.time_updater());
    XCTAssertFalse(action.completion_handler());

    auto const &start_time = action.start_time();
    auto const time = std::chrono::system_clock::now();

    XCTAssertTrue(start_time <= time);
    XCTAssertTrue((time + -100ms) < start_time);

    XCTAssertTrue(action.updatable());
}

- (void)test_create_action_null {
    ui::action action{nullptr};
    ui::continuous_action continuous_action{nullptr};
    ui::parallel_action parallel_action{nullptr};

    XCTAssertFalse(action);
    XCTAssertFalse(continuous_action);
    XCTAssertFalse(parallel_action);
}

- (void)test_create_continuous_action {
    ui::continuous_action action;

    XCTAssertEqual(action.duration(), 0.3);
    XCTAssertFalse(action.value_transformer());
}

- (void)test_updatable_finished {
    auto const start_time = std::chrono::system_clock::now();
    ui::continuous_action action{{.duration = 1.0, .action = {.start_time = start_time}}};
    auto &updatable_action = action.updatable();

    XCTAssertFalse(updatable_action.update(start_time + 999ms));
    XCTAssertTrue(updatable_action.update(start_time + 1000ms));
}

- (void)test_set_variables_to_action {
    ui::node target;
    auto const time = std::chrono::system_clock::now();
    ui::action action{{.start_time = time, .delay = 1.0}};

    action.set_target(target);
    action.set_time_updater([](auto const &time) { return false; });
    action.set_completion_handler([]() {});

    XCTAssertEqual(action.target(), target);
    XCTAssertEqual(action.start_time(), time);
    XCTAssertEqual(action.delay(), 1.0);
    XCTAssertTrue(action.time_updater());
    XCTAssertTrue(action.completion_handler());
}

- (void)test_set_variables_to_continuous_action {
    ui::continuous_action action{{.duration = 10.0}};
    ui::node target;

    action.set_value_transformer(ui::ease_out_transformer());

    XCTAssertEqual(action.duration(), 10.0);
    XCTAssertTrue(action.value_transformer());
}

- (void)test_start_time {
    auto time = std::chrono::system_clock::now();
    ui::action action{{.start_time = time + 1s}};
    auto &updatable = action.updatable();

    XCTAssertFalse(updatable.update(time));
    XCTAssertFalse(updatable.update(time + 999ms));
    XCTAssertTrue(updatable.update(time + 1s));
}

- (void)test_update_translate_action {
    ui::node target;
    auto time = std::chrono::system_clock::now();
    ui::continuous_action_args args{.duration = 1.0, .action = {.start_time = time}};
    auto action = ui::make_action(
        {.start_position = {0.0f, -1.0f}, .end_position = {1.0f, 1.0f}, .continuous_action = std::move(args)});
    action.set_target(target);

    auto &updatable = action.updatable();

    updatable.update(time);

    XCTAssertEqual(target.position().x, 0.0f);
    XCTAssertEqual(target.position().y, -1.0f);

    updatable.update(time + 500ms);

    XCTAssertEqual(target.position().x, 0.5f);
    XCTAssertEqual(target.position().y, 0.0f);

    updatable.update(time + 1s);

    XCTAssertEqual(target.position().x, 1.0f);
    XCTAssertEqual(target.position().y, 1.0f);
}

- (void)test_update_rotate_action {
    ui::node target;
    auto time = std::chrono::system_clock::now();
    ui::continuous_action_args args{.duration = 1.0, .action = {.start_time = time}};
    auto action = ui::make_action(
        {.start_angle = 0.0f, .end_angle = 360.0f, .is_shortest = false, .continuous_action = std::move(args)});
    action.set_target(target);

    auto &updatable = action.updatable();

    updatable.update(time);

    XCTAssertEqual(target.angle(), 0.0f);

    updatable.update(time + 500ms);

    XCTAssertEqual(target.angle(), 180.0f);

    updatable.update(time + 1s);

    XCTAssertEqual(target.angle(), 360.0f);
}

- (void)test_update_rotate_action_shortest_1 {
    ui::node target;
    auto time = std::chrono::system_clock::now();
    ui::continuous_action_args args{.duration = 1.0, .action = {.start_time = time}};
    auto action = ui::make_action(
        {.start_angle = 0.0f, .end_angle = 270.0f, .is_shortest = true, .continuous_action = std::move(args)});
    action.set_target(target);

    auto &updatable = action.updatable();

    updatable.update(time);

    XCTAssertEqual(target.angle(), 360.0f);

    updatable.update(time + 500ms);

    XCTAssertEqual(target.angle(), 315.0f);

    updatable.update(time + 1s);

    XCTAssertEqual(target.angle(), 270.0f);
}

- (void)test_update_rotate_action_shortest_2 {
    ui::node target;
    auto time = std::chrono::system_clock::now();
    ui::continuous_action_args args{.duration = 1.0, .action = {.start_time = time}};
    auto action = ui::make_action(
        {.start_angle = -180.0f, .end_angle = 90.0f, .is_shortest = true, .continuous_action = std::move(args)});
    action.set_target(target);
    auto &updatable = action.updatable();

    updatable.update(time);

    XCTAssertEqual(target.angle(), 180.0f);

    updatable.update(time + 500ms);

    XCTAssertEqual(target.angle(), 135.0f);

    updatable.update(time + 1s);

    XCTAssertEqual(target.angle(), 90.0f);
}

- (void)test_update_scale_action {
    ui::node target;
    auto time = std::chrono::system_clock::now();
    ui::continuous_action_args args{.duration = 1.0, .action = {.start_time = time}};
    auto action = ui::make_action(
        {.start_scale = {0.0f, -1.0f}, .end_scale = {1.0f, 1.0f}, .continuous_action = std::move(args)});
    action.set_target(target);

    auto &updatable = action.updatable();

    updatable.update(time);

    XCTAssertEqual(target.scale().width, 0.0f);
    XCTAssertEqual(target.scale().height, -1.0f);

    updatable.update(time + 500ms);

    XCTAssertEqual(target.scale().width, 0.5f);
    XCTAssertEqual(target.scale().height, 0.0f);

    updatable.update(time + 1s);

    XCTAssertEqual(target.scale().width, 1.0f);
    XCTAssertEqual(target.scale().height, 1.0f);
}

- (void)test_update_color_action {
    ui::node target;
    auto time = std::chrono::system_clock::now();
    ui::continuous_action_args args{.duration = 1.0, .action = {.start_time = time}};
    auto action = ui::make_action(
        {.start_color = {0.0f, 0.25f, 0.5f}, .end_color = {1.0f, 0.75f, 0.5f}, .continuous_action = std::move(args)});
    action.set_target(target);
    ui::mesh mesh;
    target.set_mesh(mesh);
    auto &updatable = action.updatable();

    updatable.update(time);

    XCTAssertEqual(target.color().red, 0.0f);
    XCTAssertEqual(target.color().green, 0.25f);
    XCTAssertEqual(target.color().blue, 0.5f);

    updatable.update(time + 500ms);

    XCTAssertEqual(target.color().red, 0.5f);
    XCTAssertEqual(target.color().green, 0.5f);
    XCTAssertEqual(target.color().blue, 0.5f);

    updatable.update(time + 1s);

    XCTAssertEqual(target.color().red, 1.0f);
    XCTAssertEqual(target.color().green, 0.75f);
    XCTAssertEqual(target.color().blue, 0.5f);
}

- (void)test_udpate_alpha_action {
    ui::node target;
    auto time = std::chrono::system_clock::now();
    ui::continuous_action_args args{.duration = 1.0, .action = {.start_time = time}};
    auto action = ui::make_action({.start_alpha = 1.0f, .end_alpha = 0.0f, .continuous_action = std::move(args)});
    action.set_target(target);
    ui::mesh mesh;
    target.set_mesh(mesh);
    auto &updatable = action.updatable();

    updatable.update(time);

    XCTAssertEqual(target.alpha(), 1.0f);

    updatable.update(time + 500ms);

    XCTAssertEqual(target.alpha(), 0.5f);

    updatable.update(time + 1s);

    XCTAssertEqual(target.alpha(), 0.0f);
}

- (void)test_completion_handler {
    auto time = std::chrono::system_clock::now();
    ui::continuous_action action{{.duration = 1.0, .action = {.start_time = time}}};
    auto &updatable = action.updatable();

    bool completed = false;
    action.set_completion_handler([&completed]() { completed = true; });

    updatable.update(time);

    XCTAssertFalse(completed);

    updatable.update(time + 500ms);

    XCTAssertFalse(completed);

    updatable.update(time + 1s);

    XCTAssertTrue(completed);
}

- (void)test_aciton_with_delay {
    ui::node target;
    auto time = std::chrono::system_clock::now();
    ui::continuous_action_args args = {.duration = 1.0, .action = {.delay = 2.0, .start_time = time}};
    auto action = ui::make_action({.start_angle = 0.0f, .end_angle = 1.0f, .continuous_action = std::move(args)});
    action.set_target(target);

    auto &updatable = action.updatable();

    bool completed = false;

    action.set_completion_handler([&completed]() { completed = true; });

    target.set_angle(2.0f);

    XCTAssertFalse(updatable.update(time));
    XCTAssertFalse(completed);
    XCTAssertEqual(target.angle(), 2.0f);

    XCTAssertFalse(updatable.update(time + 1999ms));
    XCTAssertFalse(completed);
    XCTAssertEqual(target.angle(), 2.0f);

    XCTAssertFalse(updatable.update(time + 2s));
    XCTAssertFalse(completed);
    XCTAssertEqual(target.angle(), 0.0f);

    XCTAssertFalse(updatable.update(time + 2999ms));
    XCTAssertFalse(completed);

    XCTAssertTrue(updatable.update(time + 3000ms));
    XCTAssertTrue(completed);
}

- (void)test_action_with_loop {
    ui::node target;
    auto time = std::chrono::system_clock::now();
    ui::continuous_action_args args = {.duration = 1.0, .loop_count = 2, .action = {.start_time = time}};
    auto action = ui::make_action({.start_angle = 0.0f, .end_angle = 1.0f, .continuous_action = std::move(args)});
    action.set_target(target);

    auto &updatable = action.updatable();

    bool completed = false;

    action.set_completion_handler([&completed]() { completed = true; });

    target.set_angle(2.0f);

    XCTAssertFalse(updatable.update(time - 1ms));
    XCTAssertFalse(completed);
    XCTAssertEqual(target.angle(), 2.0f);

    XCTAssertFalse(updatable.update(time));
    XCTAssertFalse(completed);
    XCTAssertEqual(target.angle(), 0.0f);

    XCTAssertFalse(updatable.update(time + 500ms));
    XCTAssertFalse(completed);
    XCTAssertEqual(target.angle(), 0.5f);

    XCTAssertFalse(updatable.update(time + 1s));
    XCTAssertFalse(completed);
    XCTAssertEqual(target.angle(), 0.0f);

    XCTAssertFalse(updatable.update(time + 1500ms));
    XCTAssertFalse(completed);
    XCTAssertEqual(target.angle(), 0.5f);

    XCTAssertTrue(updatable.update(time + 2s));
    XCTAssertTrue(completed);
    XCTAssertEqual(target.angle(), 1.0f);
}

- (void)test_create_parallel_action {
    ui::parallel_action parallel_action;

    XCTAssertEqual(parallel_action.actions().size(), 0);
}

- (void)test_parallel_action {
    ui::parallel_action parallel_action;

    auto time = std::chrono::system_clock::now();

    ui::continuous_action action1{{.duration = 1.0, .action = {.start_time = time}}};
    parallel_action.insert_action(std::move(action1));

    ui::continuous_action action2{{.duration = 2.0, .action = {.start_time = time}}};
    parallel_action.insert_action(std::move(action2));

    ui::continuous_action action3{{.duration = 3.0, .action = {.start_time = time}}};
    parallel_action.insert_action(std::move(action3));

    XCTAssertEqual(parallel_action.actions().size(), 3);

    XCTAssertFalse(parallel_action.updatable().update(time));
    XCTAssertEqual(parallel_action.actions().size(), 3);

    XCTAssertFalse(parallel_action.updatable().update(time + 999ms));
    XCTAssertEqual(parallel_action.actions().size(), 3);

    XCTAssertFalse(parallel_action.updatable().update(time + 1s));
    XCTAssertEqual(parallel_action.actions().size(), 2);

    XCTAssertFalse(parallel_action.updatable().update(time + 1999ms));
    XCTAssertEqual(parallel_action.actions().size(), 2);

    XCTAssertFalse(parallel_action.updatable().update(time + 2s));
    XCTAssertEqual(parallel_action.actions().size(), 1);

    XCTAssertFalse(parallel_action.updatable().update(time + 2999ms));
    XCTAssertEqual(parallel_action.actions().size(), 1);

    XCTAssertTrue(parallel_action.updatable().update(time + 3s));
    XCTAssertEqual(parallel_action.actions().size(), 0);
}

- (void)test_make_sequence {
    ui::action first_action;
    ui::continuous_action continuous_action1{{.duration = 1.0}};
    ui::action end_action;
    ui::continuous_action continuous_action2{{.duration = 0.5}};

    bool first_completed = false;
    bool rotate_completed = false;
    bool end_completed = false;
    bool scale_completed = false;
    bool sequence_completed = false;

    first_action.set_completion_handler([&first_completed] { first_completed = true; });
    continuous_action1.set_completion_handler([&rotate_completed] { rotate_completed = true; });
    end_action.set_completion_handler([&end_completed] { end_completed = true; });
    continuous_action2.set_completion_handler([&scale_completed] { scale_completed = true; });

    auto time = std::chrono::system_clock::now();

    auto action_sequence =
        ui::make_action_sequence({first_action, continuous_action1, end_action, continuous_action2}, time + 1s);
    action_sequence.set_completion_handler([&sequence_completed] { sequence_completed = true; });
    auto &updatable = action_sequence.updatable();

    XCTAssertFalse(updatable.update(time));

    XCTAssertFalse(first_completed);
    XCTAssertFalse(rotate_completed);
    XCTAssertFalse(end_completed);
    XCTAssertFalse(scale_completed);
    XCTAssertFalse(sequence_completed);

    XCTAssertFalse(updatable.update(time + 999ms));

    XCTAssertFalse(first_completed);
    XCTAssertFalse(rotate_completed);
    XCTAssertFalse(end_completed);
    XCTAssertFalse(scale_completed);
    XCTAssertFalse(sequence_completed);

    XCTAssertFalse(updatable.update(time + 1s));

    XCTAssertTrue(first_completed);
    XCTAssertFalse(rotate_completed);
    XCTAssertFalse(end_completed);
    XCTAssertFalse(scale_completed);
    XCTAssertFalse(sequence_completed);

    XCTAssertFalse(updatable.update(time + 1999ms));

    XCTAssertTrue(first_completed);
    XCTAssertFalse(rotate_completed);
    XCTAssertFalse(end_completed);
    XCTAssertFalse(scale_completed);
    XCTAssertFalse(sequence_completed);

    XCTAssertFalse(updatable.update(time + 2s));

    XCTAssertTrue(first_completed);
    XCTAssertTrue(rotate_completed);
    XCTAssertTrue(end_completed);
    XCTAssertFalse(scale_completed);
    XCTAssertFalse(sequence_completed);

    XCTAssertFalse(updatable.update(time + 2499ms));

    XCTAssertTrue(first_completed);
    XCTAssertTrue(rotate_completed);
    XCTAssertTrue(end_completed);
    XCTAssertFalse(scale_completed);
    XCTAssertFalse(sequence_completed);

    XCTAssertTrue(updatable.update(time + 2500ms));

    XCTAssertTrue(first_completed);
    XCTAssertTrue(rotate_completed);
    XCTAssertTrue(end_completed);
    XCTAssertTrue(scale_completed);
    XCTAssertTrue(sequence_completed);
}

@end
