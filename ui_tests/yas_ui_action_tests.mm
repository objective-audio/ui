//
//  yas_ui_action_tests.mm
//

#import <XCTest/XCTest.h>
#import <ui/ui.h>
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
    XCTAssertFalse(action->time_updater);
    XCTAssertFalse(action->completion_handler);
    XCTAssertFalse(action->is_continous());
    XCTAssertFalse(action->is_parallel());

    auto const &begin_time = action->begin_time();
    auto const time = std::chrono::system_clock::now();

    XCTAssertTrue(begin_time <= time);
    XCTAssertTrue((time + -100ms) < begin_time);

    XCTAssertTrue(action);
}

- (void)test_create_continuous_action {
    auto action = ui::action::make_continuous();

    XCTAssertEqual(action->continuous()->duration(), 0.3);
    XCTAssertFalse(action->continuous()->value_transformer);
    XCTAssertTrue(action->is_continous());
    XCTAssertFalse(action->is_parallel());
}

- (void)test_action_finished {
    auto const begin_time = std::chrono::system_clock::now();
    auto action = ui::action::make_continuous({.begin_time = begin_time}, {.duration = 1.0});

    XCTAssertFalse(action->update(begin_time + 999ms));
    XCTAssertTrue(action->update(begin_time + 1000ms));
}

- (void)test_set_variables_to_action {
    auto target = ui::node::make_shared();
    auto const time = std::chrono::system_clock::now();
    auto action = ui::action::make_shared({.begin_time = time, .delay = 1.0});

    action->set_target(target);
    action->time_updater = [](auto const &time) { return false; };
    action->completion_handler = [] {};

    XCTAssertEqual(action->target(), target);
    XCTAssertEqual(action->begin_time(), time);
    XCTAssertEqual(action->delay(), 1.0);
    XCTAssertTrue(action->time_updater);
    XCTAssertTrue(action->completion_handler);
}

- (void)test_set_variables_to_continuous_action {
    auto action = ui::action::make_continuous({}, {.duration = 10.0});
    auto target = ui::node::make_shared();

    action->continuous()->value_transformer = ui::ease_out_sine_transformer();

    XCTAssertEqual(action->continuous()->duration(), 10.0);
    XCTAssertTrue(action->continuous()->value_transformer);
}

- (void)test_begin_time {
    auto time = std::chrono::system_clock::now();
    auto action = ui::action::make_shared({.begin_time = time + 1s});

    XCTAssertFalse(action->update(time));
    XCTAssertFalse(action->update(time + 999ms));
    XCTAssertTrue(action->update(time + 1s));
}

- (void)test_completion_handler {
    auto time = std::chrono::system_clock::now();
    auto action = ui::action::make_continuous({.begin_time = time}, {.duration = 1.0});

    bool completed = false;
    action->completion_handler = [&completed]() { completed = true; };

    action->update(time);

    XCTAssertFalse(completed);

    action->update(time + 500ms);

    XCTAssertFalse(completed);

    action->update(time + 1s);

    XCTAssertTrue(completed);
}

- (void)test_continuous_action_with_delay {
    auto time = std::chrono::system_clock::now();
    auto action = ui::action::make_continuous({.delay = 2.0, .begin_time = time}, {.duration = 1.0});

    bool completed = false;
    double updated_value = -1.0f;

    action->continuous()->value_updater = [&updated_value](auto const value) { updated_value = value; };
    action->completion_handler = [&completed]() { completed = true; };

    XCTAssertFalse(action->update(time));
    XCTAssertFalse(completed);
    XCTAssertEqual(updated_value, -1.0f);

    XCTAssertFalse(action->update(time + 1999ms));
    XCTAssertFalse(completed);
    XCTAssertEqual(updated_value, -1.0f);

    XCTAssertFalse(action->update(time + 2s));
    XCTAssertFalse(completed);
    XCTAssertEqual(updated_value, 0.0f);

    XCTAssertFalse(action->update(time + 2999ms));
    XCTAssertFalse(completed);

    XCTAssertTrue(action->update(time + 3000ms));
    XCTAssertTrue(completed);
    XCTAssertEqual(updated_value, 1.0f);
}

- (void)test_continuous_action_with_loop {
    auto time = std::chrono::system_clock::now();
    auto action = ui::action::make_continuous({.begin_time = time}, {.duration = 1.0, .loop_count = 2});

    bool completed = false;
    double updated_value = -1.0f;

    action->continuous()->value_updater = [&updated_value](auto const value) { updated_value = value; };
    action->completion_handler = [&completed]() { completed = true; };

    XCTAssertFalse(action->update(time - 1ms));
    XCTAssertFalse(completed);
    XCTAssertEqual(updated_value, -1.0f);

    XCTAssertFalse(action->update(time));
    XCTAssertFalse(completed);
    XCTAssertEqual(updated_value, 0.0f);

    XCTAssertFalse(action->update(time + 500ms));
    XCTAssertFalse(completed);
    XCTAssertEqual(updated_value, 0.5f);

    XCTAssertFalse(action->update(time + 1s));
    XCTAssertFalse(completed);
    XCTAssertEqual(updated_value, 0.0f);

    XCTAssertFalse(action->update(time + 1500ms));
    XCTAssertFalse(completed);
    XCTAssertEqual(updated_value, 0.5f);

    XCTAssertTrue(action->update(time + 2s));
    XCTAssertTrue(completed);
    XCTAssertEqual(updated_value, 1.0f);
}

- (void)test_create_parallel_action {
    auto action = ui::action::make_parallel();

    XCTAssertEqual(action->parallel()->actions().size(), 0);
    XCTAssertTrue(action->is_parallel());
    XCTAssertFalse(action->is_continous());
}

- (void)test_parallel_action {
    auto time = std::chrono::system_clock::now();

    auto action1 = ui::action::make_continuous({.begin_time = time}, {.duration = 1.0});
    auto action2 = ui::action::make_continuous({.begin_time = time}, {.duration = 2.0});

    auto parallel_action = ui::action::make_parallel({}, {.actions = {std::move(action1), std::move(action2)}});

    auto action3 = ui::action::make_continuous({.begin_time = time}, {.duration = 3.0});
    parallel_action->parallel()->insert_action(std::move(action3));

    XCTAssertEqual(parallel_action->parallel()->actions().size(), 3);

    XCTAssertFalse(parallel_action->update(time));
    XCTAssertEqual(parallel_action->parallel()->actions().size(), 3);

    XCTAssertFalse(parallel_action->update(time + 999ms));
    XCTAssertEqual(parallel_action->parallel()->actions().size(), 3);

    XCTAssertFalse(parallel_action->update(time + 1s));
    XCTAssertEqual(parallel_action->parallel()->actions().size(), 2);

    XCTAssertFalse(parallel_action->update(time + 1999ms));
    XCTAssertEqual(parallel_action->parallel()->actions().size(), 2);

    XCTAssertFalse(parallel_action->update(time + 2s));
    XCTAssertEqual(parallel_action->parallel()->actions().size(), 1);

    XCTAssertFalse(parallel_action->update(time + 2999ms));
    XCTAssertEqual(parallel_action->parallel()->actions().size(), 1);

    XCTAssertTrue(parallel_action->update(time + 3s));
    XCTAssertEqual(parallel_action->parallel()->actions().size(), 0);
}

- (void)test_make_action_sequence {
    auto first_action = ui::action::make_shared();
    auto continuous_action1 = ui::action::make_continuous({}, {.duration = 1.0});
    auto end_action = ui::action::make_shared();
    auto continuous_action2 = ui::action::make_continuous({}, {.duration = 0.5});

    bool first_completed = false;
    bool rotate_completed = false;
    bool end_completed = false;
    bool scale_completed = false;
    bool sequence_completed = false;

    first_action->completion_handler = [&first_completed] { first_completed = true; };
    continuous_action1->completion_handler = [&rotate_completed] { rotate_completed = true; };
    end_action->completion_handler = [&end_completed] { end_completed = true; };
    continuous_action2->completion_handler = [&scale_completed] { scale_completed = true; };

    auto time = std::chrono::system_clock::now();

    auto action_sequence =
        ui::action::make_sequence({first_action, continuous_action1, end_action, continuous_action2}, time + 1s);
    action_sequence->completion_handler = [&sequence_completed] { sequence_completed = true; };
    auto const action = action_sequence;

    XCTAssertFalse(action->update(time));

    XCTAssertFalse(first_completed);
    XCTAssertFalse(rotate_completed);
    XCTAssertFalse(end_completed);
    XCTAssertFalse(scale_completed);
    XCTAssertFalse(sequence_completed);

    XCTAssertFalse(action->update(time + 999ms));

    XCTAssertFalse(first_completed);
    XCTAssertFalse(rotate_completed);
    XCTAssertFalse(end_completed);
    XCTAssertFalse(scale_completed);
    XCTAssertFalse(sequence_completed);

    XCTAssertFalse(action->update(time + 1s));

    XCTAssertTrue(first_completed);
    XCTAssertFalse(rotate_completed);
    XCTAssertFalse(end_completed);
    XCTAssertFalse(scale_completed);
    XCTAssertFalse(sequence_completed);

    XCTAssertFalse(action->update(time + 1999ms));

    XCTAssertTrue(first_completed);
    XCTAssertFalse(rotate_completed);
    XCTAssertFalse(end_completed);
    XCTAssertFalse(scale_completed);
    XCTAssertFalse(sequence_completed);

    XCTAssertFalse(action->update(time + 2s));

    XCTAssertTrue(first_completed);
    XCTAssertTrue(rotate_completed);
    XCTAssertTrue(end_completed);
    XCTAssertFalse(scale_completed);
    XCTAssertFalse(sequence_completed);

    XCTAssertFalse(action->update(time + 2499ms));

    XCTAssertTrue(first_completed);
    XCTAssertTrue(rotate_completed);
    XCTAssertTrue(end_completed);
    XCTAssertFalse(scale_completed);
    XCTAssertFalse(sequence_completed);

    XCTAssertTrue(action->update(time + 2500ms));

    XCTAssertTrue(first_completed);
    XCTAssertTrue(rotate_completed);
    XCTAssertTrue(end_completed);
    XCTAssertTrue(scale_completed);
    XCTAssertTrue(sequence_completed);
}

@end
