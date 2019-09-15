//
//  yas_ui_action_tests.mm
//

#import <XCTest/XCTest.h>
#import <ui/yas_ui_action.h>
#import <ui/yas_ui_mesh.h>
#import <ui/yas_ui_node.h>
#import <unordered_set>

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
    auto action = ui::action::make_shared();

    XCTAssertFalse(action->target());
    XCTAssertEqual(action->delay(), 0.0);
    XCTAssertFalse(action->time_updater());
    XCTAssertFalse(action->completion_handler());

    auto const &begin_time = action->begin_time();
    auto const time = std::chrono::system_clock::now();

    XCTAssertTrue(begin_time <= time);
    XCTAssertTrue((time + -100ms) < begin_time);

    XCTAssertTrue(ui::updatable_action::cast(action));
}

- (void)test_create_continuous_action {
    auto action = ui::continuous_action::make_shared();

    XCTAssertEqual(action->duration(), 0.3);
    XCTAssertFalse(action->value_transformer());
}

- (void)test_updatable_finished {
    auto const begin_time = std::chrono::system_clock::now();
    auto action = ui::continuous_action::make_shared({.duration = 1.0, .action = {.begin_time = begin_time}});
    auto const updatable = ui::updatable_action::cast(action);

    XCTAssertFalse(updatable->update(begin_time + 999ms));
    XCTAssertTrue(updatable->update(begin_time + 1000ms));
}

- (void)test_set_variables_to_action {
    auto target = ui::node::make_shared();
    auto const time = std::chrono::system_clock::now();
    auto action = ui::action::make_shared({.begin_time = time, .delay = 1.0});

    action->set_target(target);
    action->set_time_updater([](auto const &time) { return false; });
    action->set_completion_handler([]() {});

    XCTAssertEqual(action->target(), target);
    XCTAssertEqual(action->begin_time(), time);
    XCTAssertEqual(action->delay(), 1.0);
    XCTAssertTrue(action->time_updater());
    XCTAssertTrue(action->completion_handler());
}

- (void)test_set_variables_to_continuous_action {
    auto action = ui::continuous_action::make_shared({.duration = 10.0});
    auto target = ui::node::make_shared();

    action->set_value_transformer(ui::ease_out_sine_transformer());

    XCTAssertEqual(action->duration(), 10.0);
    XCTAssertTrue(action->value_transformer());
}

- (void)test_begin_time {
    auto time = std::chrono::system_clock::now();
    auto action = ui::action::make_shared({.begin_time = time + 1s});
    auto const updatable = ui::updatable_action::cast(action);

    XCTAssertFalse(updatable->update(time));
    XCTAssertFalse(updatable->update(time + 999ms));
    XCTAssertTrue(updatable->update(time + 1s));
}

- (void)test_completion_handler {
    auto time = std::chrono::system_clock::now();
    auto action = ui::continuous_action::make_shared({.duration = 1.0, .action = {.begin_time = time}});
    auto const updatable = ui::updatable_action::cast(action);

    bool completed = false;
    action->set_completion_handler([&completed]() { completed = true; });

    updatable->update(time);

    XCTAssertFalse(completed);

    updatable->update(time + 500ms);

    XCTAssertFalse(completed);

    updatable->update(time + 1s);

    XCTAssertTrue(completed);
}

- (void)test_continuous_action_with_delay {
    auto time = std::chrono::system_clock::now();
    ui::continuous_action::args args = {.duration = 1.0, .action = {.delay = 2.0, .begin_time = time}};

    auto action = ui::continuous_action::make_shared(std::move(args));

    auto const updatable = ui::updatable_action::cast(action);

    bool completed = false;
    double updated_value = -1.0f;

    action->set_value_updater([&updated_value](auto const value) { updated_value = value; });
    action->set_completion_handler([&completed]() { completed = true; });

    XCTAssertFalse(updatable->update(time));
    XCTAssertFalse(completed);
    XCTAssertEqual(updated_value, -1.0f);

    XCTAssertFalse(updatable->update(time + 1999ms));
    XCTAssertFalse(completed);
    XCTAssertEqual(updated_value, -1.0f);

    XCTAssertFalse(updatable->update(time + 2s));
    XCTAssertFalse(completed);
    XCTAssertEqual(updated_value, 0.0f);

    XCTAssertFalse(updatable->update(time + 2999ms));
    XCTAssertFalse(completed);

    XCTAssertTrue(updatable->update(time + 3000ms));
    XCTAssertTrue(completed);
    XCTAssertEqual(updated_value, 1.0f);
}

- (void)test_continuous_action_with_loop {
    auto time = std::chrono::system_clock::now();
    ui::continuous_action::args args = {.duration = 1.0, .loop_count = 2, .action = {.begin_time = time}};
    auto action = ui::continuous_action::make_shared(std::move(args));

    auto const updatable = ui::updatable_action::cast(action);

    bool completed = false;
    double updated_value = -1.0f;

    action->set_value_updater([&updated_value](auto const value) { updated_value = value; });
    action->set_completion_handler([&completed]() { completed = true; });

    XCTAssertFalse(updatable->update(time - 1ms));
    XCTAssertFalse(completed);
    XCTAssertEqual(updated_value, -1.0f);

    XCTAssertFalse(updatable->update(time));
    XCTAssertFalse(completed);
    XCTAssertEqual(updated_value, 0.0f);

    XCTAssertFalse(updatable->update(time + 500ms));
    XCTAssertFalse(completed);
    XCTAssertEqual(updated_value, 0.5f);

    XCTAssertFalse(updatable->update(time + 1s));
    XCTAssertFalse(completed);
    XCTAssertEqual(updated_value, 0.0f);

    XCTAssertFalse(updatable->update(time + 1500ms));
    XCTAssertFalse(completed);
    XCTAssertEqual(updated_value, 0.5f);

    XCTAssertTrue(updatable->update(time + 2s));
    XCTAssertTrue(completed);
    XCTAssertEqual(updated_value, 1.0f);
}

- (void)test_create_parallel_action {
    auto parallel_action = ui::parallel_action::make_shared();

    XCTAssertEqual(parallel_action->actions().size(), 0);
}

- (void)test_parallel_action {
    auto time = std::chrono::system_clock::now();

    auto action1 = ui::continuous_action::make_shared({.duration = 1.0, .action = {.begin_time = time}});
    auto action2 = ui::continuous_action::make_shared({.duration = 2.0, .action = {.begin_time = time}});

    auto parallel_action = ui::parallel_action::make_shared({.actions = {std::move(action1), std::move(action2)}});

    auto action3 = ui::continuous_action::make_shared({.duration = 3.0, .action = {.begin_time = time}});
    parallel_action->insert_action(std::move(action3));

    XCTAssertEqual(parallel_action->actions().size(), 3);

    XCTAssertFalse(ui::updatable_action::cast(parallel_action)->update(time));
    XCTAssertEqual(parallel_action->actions().size(), 3);

    XCTAssertFalse(ui::updatable_action::cast(parallel_action)->update(time + 999ms));
    XCTAssertEqual(parallel_action->actions().size(), 3);

    XCTAssertFalse(ui::updatable_action::cast(parallel_action)->update(time + 1s));
    XCTAssertEqual(parallel_action->actions().size(), 2);

    XCTAssertFalse(ui::updatable_action::cast(parallel_action)->update(time + 1999ms));
    XCTAssertEqual(parallel_action->actions().size(), 2);

    XCTAssertFalse(ui::updatable_action::cast(parallel_action)->update(time + 2s));
    XCTAssertEqual(parallel_action->actions().size(), 1);

    XCTAssertFalse(ui::updatable_action::cast(parallel_action)->update(time + 2999ms));
    XCTAssertEqual(parallel_action->actions().size(), 1);

    XCTAssertTrue(ui::updatable_action::cast(parallel_action)->update(time + 3s));
    XCTAssertEqual(parallel_action->actions().size(), 0);
}

- (void)test_make_action_sequence {
    auto first_action = ui::action::make_shared();
    auto continuous_action1 = ui::continuous_action::make_shared({.duration = 1.0});
    auto end_action = ui::action::make_shared();
    auto continuous_action2 = ui::continuous_action::make_shared({.duration = 0.5});

    bool first_completed = false;
    bool rotate_completed = false;
    bool end_completed = false;
    bool scale_completed = false;
    bool sequence_completed = false;

    first_action->set_completion_handler([&first_completed] { first_completed = true; });
    continuous_action1->set_completion_handler([&rotate_completed] { rotate_completed = true; });
    end_action->set_completion_handler([&end_completed] { end_completed = true; });
    continuous_action2->set_completion_handler([&scale_completed] { scale_completed = true; });

    auto time = std::chrono::system_clock::now();

    auto action_sequence =
        ui::make_action_sequence({first_action, continuous_action1, end_action, continuous_action2}, time + 1s);
    action_sequence->set_completion_handler([&sequence_completed] { sequence_completed = true; });
    auto const updatable = ui::updatable_action::cast(action_sequence);

    XCTAssertFalse(updatable->update(time));

    XCTAssertFalse(first_completed);
    XCTAssertFalse(rotate_completed);
    XCTAssertFalse(end_completed);
    XCTAssertFalse(scale_completed);
    XCTAssertFalse(sequence_completed);

    XCTAssertFalse(updatable->update(time + 999ms));

    XCTAssertFalse(first_completed);
    XCTAssertFalse(rotate_completed);
    XCTAssertFalse(end_completed);
    XCTAssertFalse(scale_completed);
    XCTAssertFalse(sequence_completed);

    XCTAssertFalse(updatable->update(time + 1s));

    XCTAssertTrue(first_completed);
    XCTAssertFalse(rotate_completed);
    XCTAssertFalse(end_completed);
    XCTAssertFalse(scale_completed);
    XCTAssertFalse(sequence_completed);

    XCTAssertFalse(updatable->update(time + 1999ms));

    XCTAssertTrue(first_completed);
    XCTAssertFalse(rotate_completed);
    XCTAssertFalse(end_completed);
    XCTAssertFalse(scale_completed);
    XCTAssertFalse(sequence_completed);

    XCTAssertFalse(updatable->update(time + 2s));

    XCTAssertTrue(first_completed);
    XCTAssertTrue(rotate_completed);
    XCTAssertTrue(end_completed);
    XCTAssertFalse(scale_completed);
    XCTAssertFalse(sequence_completed);

    XCTAssertFalse(updatable->update(time + 2499ms));

    XCTAssertTrue(first_completed);
    XCTAssertTrue(rotate_completed);
    XCTAssertTrue(end_completed);
    XCTAssertFalse(scale_completed);
    XCTAssertFalse(sequence_completed);

    XCTAssertTrue(updatable->update(time + 2500ms));

    XCTAssertTrue(first_completed);
    XCTAssertTrue(rotate_completed);
    XCTAssertTrue(end_completed);
    XCTAssertTrue(scale_completed);
    XCTAssertTrue(sequence_completed);
}

@end
