//
//  yas_ui_event_tests.mm
//

#import <XCTest/XCTest.h>
#import <ui/yas_ui_umbrella.h>
#import <sstream>

using namespace yas;
using namespace yas::ui;
using manager_for_view_ptr = std::shared_ptr<event_manager_for_view>;

@interface yas_ui_event_tests : XCTestCase

@end

@implementation yas_ui_event_tests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)test_event_phase_to_string {
    XCTAssertEqual(to_string(event_phase::none), "none");
    XCTAssertEqual(to_string(event_phase::began), "began");
    XCTAssertEqual(to_string(event_phase::stationary), "stationary");
    XCTAssertEqual(to_string(event_phase::changed), "changed");
    XCTAssertEqual(to_string(event_phase::ended), "ended");
    XCTAssertEqual(to_string(event_phase::canceled), "canceled");
    XCTAssertEqual(to_string(event_phase::may_begin), "may_begin");
}

- (void)test_modifier_flags_to_string {
    XCTAssertEqual(to_string(modifier_flags::alpha_shift), "alpha_shift");
    XCTAssertEqual(to_string(modifier_flags::shift), "shift");
    XCTAssertEqual(to_string(modifier_flags::control), "control");
    XCTAssertEqual(to_string(modifier_flags::alternate), "alternate");
    XCTAssertEqual(to_string(modifier_flags::command), "command");
    XCTAssertEqual(to_string(modifier_flags::numeric_pad), "numeric_pad");
    XCTAssertEqual(to_string(modifier_flags::help), "help");
    XCTAssertEqual(to_string(modifier_flags::function), "function");
}

- (void)test_event_type_to_string {
    XCTAssertEqual(to_string(event_type::cursor), "cursor");
    XCTAssertEqual(to_string(event_type::touch), "touch");
    XCTAssertEqual(to_string(event_type::key), "key");
    XCTAssertEqual(to_string(event_type::modifier), "modifier");
}

- (void)test_event_phase_ostream {
    auto const phases = {event_phase::none,  event_phase::began,    event_phase::stationary, event_phase::changed,
                         event_phase::ended, event_phase::canceled, event_phase::may_begin};

    for (auto const &phase : phases) {
        std::ostringstream stream;
        stream << phase;
        XCTAssertEqual(stream.str(), to_string(phase));
    }
}

- (void)test_modifier_flags_ostream {
    auto const flags = {modifier_flags::alpha_shift, modifier_flags::shift,   modifier_flags::control,
                        modifier_flags::alternate,   modifier_flags::command, modifier_flags::numeric_pad,
                        modifier_flags::help,        modifier_flags::function};

    for (auto const &flag : flags) {
        std::ostringstream stream;
        stream << flag;
        XCTAssertEqual(stream.str(), to_string(flag));
    }
}

- (void)test_event_manager_method_ostream {
    auto const methods = {event_type::cursor, event_type::touch, event_type::key, event_type::modifier};

    for (auto const &method : methods) {
        std::ostringstream stream;
        stream << method;
        XCTAssertEqual(stream.str(), to_string(method));
    }
}

- (void)test_create_cursor_event {
    cursor_event const value{{1.0f, 2.0f}, 3.0};

    XCTAssertEqual(value.position.x, 1.0f);
    XCTAssertEqual(value.position.y, 2.0f);
    XCTAssertEqual(value.timestamp, 3.0);
}

- (void)test_create_touch_event {
    touch_event const value{{.kind = touch_kind::touch, .identifier = 10}, {4.0f, 8.0f}, 16.0};

    XCTAssertEqual(value.touch_id, (touch_id{.kind = touch_kind::touch, .identifier = 10}));
    XCTAssertEqual(value.position.x, 4.0f);
    XCTAssertEqual(value.position.y, 8.0f);
    XCTAssertEqual(value.timestamp, 16.0);
}

- (void)test_create_key_event {
    key_event const value{5, "a", "B", 6.0};

    XCTAssertEqual(value.key_code, 5);
    XCTAssertEqual(value.characters, "a");
    XCTAssertEqual(value.raw_characters, "B");
    XCTAssertEqual(value.timestamp, 6.0);
}

- (void)test_create_modifier_event {
    modifier_event const value{modifier_flags::alpha_shift, 7.0};

    XCTAssertEqual(value.flag, modifier_flags::alpha_shift);
    XCTAssertEqual(value.timestamp, 7.0);
}

- (void)test_is_equal_cursor_event {
    cursor_event const value1{{1.0f, 2.0f}, 5.0};
    cursor_event const value2{{3.0f, 4.0f}, 6.0};

    // always equal

    XCTAssertTrue(value1 == value2);
    XCTAssertFalse(value1 != value2);
}

- (void)test_is_equal_touch_event {
    touch_event const value1{{.kind = touch_kind::mouse, .identifier = 5}, {4.0f, 8.0f}, 16.0};
    touch_event const value2{{.kind = touch_kind::mouse, .identifier = 5}, {16.0f, 32.0f}, 32.0};
    touch_event const value3{{.kind = touch_kind::mouse, .identifier = 6}, {4.0f, 8.0f}, 16.0};

    // compare identifier

    XCTAssertTrue(value1 == value2);
    XCTAssertFalse(value1 == value3);

    XCTAssertFalse(value1 != value2);
    XCTAssertTrue(value1 != value3);
}

- (void)test_is_equal_key_event {
    key_event const value1{7, "a", "B", 9.0};
    key_event const value2{7, "c", "D", 10.0};
    key_event const value3{8, "a", "B", 9.0};

    // compare key_code

    XCTAssertTrue(value1 == value2);
    XCTAssertFalse(value1 == value3);

    XCTAssertFalse(value1 != value2);
    XCTAssertTrue(value1 != value3);
}

- (void)test_is_equal_modifier_event {
    modifier_event const value1{modifier_flags::shift, 20.0};
    modifier_event const value2{modifier_flags::shift, 30.0};
    modifier_event const value3{modifier_flags::control, 20.0};

    // compare flag

    XCTAssertTrue(value1 == value2);
    XCTAssertFalse(value1 == value3);

    XCTAssertFalse(value1 != value2);
    XCTAssertTrue(value1 != value3);
}

- (void)test_create_event_of_cursor {
    auto const event = event::make_shared(cursor_tag);

    XCTAssertTrue(event);
    XCTAssertTrue(event->type_info() == typeid(cursor));
}

- (void)test_create_event_of_touch {
    auto const event = event::make_shared(touch_tag);

    XCTAssertTrue(event);
    XCTAssertTrue(event->type_info() == typeid(touch));
}

- (void)test_create_event_of_key {
    auto const event = event::make_shared(key_tag);

    XCTAssertTrue(event);
    XCTAssertTrue(event->type_info() == typeid(key));
}

- (void)test_create_event_of_modifier {
    auto const event = event::make_shared(modifier_tag);

    XCTAssertTrue(event);
    XCTAssertTrue(event->type_info() == typeid(modifier));
}

- (void)test_phase {
    auto const event = event::make_shared(cursor_tag);

    XCTAssertEqual(event->phase(), event_phase::none);

    event->set_phase(event_phase::began);

    XCTAssertEqual(event->phase(), event_phase::began);
}

- (void)test_is_equal_event {
    auto const cursor_event = event::make_shared(cursor_tag);
    auto const touch_event1 = event::make_shared(touch_tag);
    auto const touch_event2 = event::make_shared(touch_tag);
    auto const touch_event3 = event::make_shared(touch_tag);

    cursor_event->set<cursor>(ui::cursor_event{{.v = 0.0f}, 10.0});
    touch_event1->set<touch>(touch_event{{.kind = touch_kind::touch, .identifier = 1}, {.v = 0.0f}, 10.0});
    touch_event2->set<touch>(touch_event{{.kind = touch_kind::touch, .identifier = 1}, {.v = 0.0f}, 11.0});
    touch_event3->set<touch>(touch_event{{.kind = touch_kind::touch, .identifier = 2}, {.v = 0.0f}, 12.0});

    XCTAssertTrue(*touch_event1 == *touch_event1);
    XCTAssertTrue(*touch_event1 == *touch_event2);
    XCTAssertFalse(*touch_event1 == *touch_event3);
    XCTAssertFalse(*touch_event1 == *cursor_event);

    XCTAssertFalse(*touch_event1 != *touch_event1);
    XCTAssertFalse(*touch_event1 != *touch_event2);
    XCTAssertTrue(*touch_event1 != *touch_event3);
    XCTAssertTrue(*touch_event1 != *cursor_event);
}

- (void)test_cursor_event_accessor {
    auto const event = event::make_shared(cursor_tag);

    XCTAssertTrue(typeid(event->get<cursor>()) == typeid(cursor_event));

    event->set<cursor>(cursor_event{{0.5f, 1.5f}, 100.0});

    auto const &pos = event->get<cursor>().position;
    XCTAssertEqual(pos.x, 0.5f);
    XCTAssertEqual(pos.y, 1.5f);
    auto const timestamp = event->get<cursor>().timestamp;
    XCTAssertEqual(timestamp, 100.0);
}

- (void)test_touch_event_accessor {
    auto const event = event::make_shared(touch_tag);

    XCTAssertTrue(typeid(event->get<touch>()) == typeid(touch_event));

    event->set<touch>(touch_event{{.kind = touch_kind::touch, .identifier = 11}, {2.5f, 3.5f}, 200.0});

    auto const &value = event->get<touch>();
    auto const &pos = value.position;
    XCTAssertEqual(value.touch_id, (touch_id{.kind = touch_kind::touch, .identifier = 11}));
    XCTAssertEqual(pos.x, 2.5f);
    XCTAssertEqual(pos.y, 3.5f);
    auto const timestamp = event->get<touch>().timestamp;
    XCTAssertEqual(timestamp, 200.0);
}

- (void)test_key_event_accessor {
    auto const event = event::make_shared(key_tag);

    XCTAssertTrue(typeid(event->get<key>()) == typeid(key_event));

    event->set<key>(key_event{23, "4", "5", 300.0});

    auto const &value = event->get<key>();
    XCTAssertEqual(value.key_code, 23);
    XCTAssertEqual(value.characters, "4");
    XCTAssertEqual(value.raw_characters, "5");
    XCTAssertEqual(value.timestamp, 300.0);
}

- (void)test_modifier_event_accessor {
    auto const event = event::make_shared(modifier_tag);

    XCTAssertTrue(typeid(event->get<modifier>()) == typeid(modifier_event));

    event->set<modifier>(modifier_event{modifier_flags::command, 400.0});

    auto const &value = event->get<modifier>();
    XCTAssertEqual(value.flag, modifier_flags::command);
    XCTAssertEqual(value.timestamp, 400.0);
}

- (void)test_create_manager {
    auto const manager = event_manager::make_shared();

    XCTAssertTrue(manager);
    XCTAssertTrue(static_cast<std::shared_ptr<event_manager_for_view>>(manager));
}

- (void)test_input_cursor_event_began {
    auto manager = event_manager::make_shared();
    manager_for_view_ptr const manager_for_view = manager;

    bool called = false;

    auto canceller = manager
                         ->observe([&called, self](std::shared_ptr<event> const &event) {
                             XCTAssertEqual(event->type(), event_type::cursor);

                             auto const &value = event->get<cursor>();
                             XCTAssertEqual(value.position.x, 0.25f);
                             XCTAssertEqual(value.position.y, 0.125f);
                             XCTAssertEqual(value.timestamp, 101.0);

                             called = true;
                         })
                         .end();

    manager_for_view->input_cursor_event(cursor_phase::began, cursor_event{{0.25f, 0.125f}, 101.0});

    XCTAssertTrue(called);

    canceller->cancel();
}

- (void)test_input_cursor_event_changed {
    auto manager = event_manager::make_shared();
    manager_for_view_ptr const manager_for_view = manager;

    int called_count = 0;

    auto canceller = manager
                         ->observe([&called_count, self](std::shared_ptr<event> const &event) {
                             XCTAssertEqual(event->type(), event_type::cursor);

                             ++called_count;
                         })
                         .end();

    // began〜endedの間のみchangedが受け入れられる

    manager_for_view->input_cursor_event(cursor_phase::changed, cursor_event{{1.0f, 1.0f}, 101.0});

    XCTAssertEqual(called_count, 0);

    manager_for_view->input_cursor_event(cursor_phase::began, cursor_event{{1.0f, 1.0f}, 101.0});

    XCTAssertEqual(called_count, 1);

    manager_for_view->input_cursor_event(cursor_phase::changed, cursor_event{{1.0f, 1.0f}, 101.0});

    XCTAssertEqual(called_count, 2);

    manager_for_view->input_cursor_event(cursor_phase::ended, cursor_event{{1.0f, 1.0f}, 101.0});

    XCTAssertEqual(called_count, 3);

    manager_for_view->input_cursor_event(cursor_phase::changed, cursor_event{{1.0f, 1.0f}, 101.0});

    XCTAssertEqual(called_count, 3);

    canceller->cancel();
}

- (void)test_input_touch_event_began {
    auto const manager = event_manager::make_shared();
    manager_for_view_ptr const manager_for_view = manager;

    bool called = false;

    auto canceller = manager
                         ->observe([&called, self](std::shared_ptr<event> const &event) {
                             XCTAssertEqual(event->type(), event_type::touch);

                             auto const &value = event->get<touch>();
                             XCTAssertEqual(value.touch_id, (touch_id{.kind = touch_kind::touch, .identifier = 100}));
                             XCTAssertEqual(value.position.x, 256.0f);
                             XCTAssertEqual(value.position.y, 512.0f);
                             XCTAssertEqual(value.timestamp, 201.0);

                             called = true;
                         })
                         .end();

    manager_for_view->input_touch_event(
        event_phase::began, touch_event{{.kind = touch_kind::touch, .identifier = 100}, {256.0f, 512.0f}, 201.0});

    XCTAssertTrue(called);

    canceller->cancel();
}

- (void)test_input_key_event_began {
    auto const manager = event_manager::make_shared();
    manager_for_view_ptr const manager_for_view = manager;

    bool called = false;

    auto canceller = manager
                         ->observe([&called, self](std::shared_ptr<event> const &event) {
                             XCTAssertEqual(event->type(), event_type::key);

                             auto const &value = event->get<key>();
                             XCTAssertEqual(value.key_code, 200);
                             XCTAssertEqual(value.characters, "xyz");
                             XCTAssertEqual(value.raw_characters, "uvw");
                             XCTAssertEqual(value.timestamp, 301.0);

                             called = true;
                         })
                         .end();

    manager_for_view->input_key_event(event_phase::began, key_event{200, "xyz", "uvw", 301.0});

    XCTAssertTrue(called);

    canceller->cancel();
}

- (void)test_input_modifier_event_began {
    auto const manager = event_manager::make_shared();
    manager_for_view_ptr const manager_for_view = manager;

    bool alt_called = false;
    bool func_called = false;

    auto canceller = manager
                         ->observe([&alt_called, &func_called, self](std::shared_ptr<event> const &event) {
                             XCTAssertEqual(event->type(), event_type::modifier);

                             auto const &value = event->get<modifier>();

                             if (value.flag == modifier_flags::alternate) {
                                 alt_called = true;
                             }

                             if (value.flag == modifier_flags::function) {
                                 func_called = true;
                             }
                         })
                         .end();

    manager_for_view->input_modifier_event(modifier_flags(modifier_flags::alternate | modifier_flags::function), 0.0);

    XCTAssertTrue(alt_called);
    XCTAssertTrue(func_called);

    canceller->cancel();
}

- (void)test_input_cursor_events {
    auto const manager = event_manager::make_shared();
    manager_for_view_ptr const manager_for_view = manager;

    bool began_called = false;
    bool ended_called = false;

    auto canceller = manager
                         ->observe([&began_called, &ended_called, self](std::shared_ptr<event> const &event) {
                             XCTAssertEqual(event->type(), event_type::cursor);

                             if (event->phase() == event_phase::began) {
                                 began_called = true;
                             } else if (event->phase() == event_phase::ended) {
                                 ended_called = true;
                             }
                         })
                         .end();

    manager_for_view->input_cursor_event(cursor_phase::began, cursor_event{{.v = 2.0f}, 0.0});  // outsize of view

    XCTAssertFalse(began_called);
    XCTAssertFalse(ended_called);

    manager_for_view->input_cursor_event(cursor_phase::began, cursor_event{{.v = 0.0f}, 0.0});  // inside of view

    XCTAssertTrue(began_called);
    began_called = false;
    XCTAssertFalse(ended_called);

    manager_for_view->input_cursor_event(cursor_phase::began, cursor_event{{.v = 0.0f}, 0.0});  // inside of view

    XCTAssertFalse(began_called);
    XCTAssertFalse(ended_called);

    manager_for_view->input_cursor_event(cursor_phase::began, cursor_event{{.v = -2.0f}, 0.0});  // outsize of view

    XCTAssertFalse(began_called);
    XCTAssertTrue(ended_called);
    ended_called = false;

    manager_for_view->input_cursor_event(cursor_phase::began, cursor_event{{.v = -2.0f}, 0.0});  // outsize of view

    XCTAssertFalse(began_called);
    XCTAssertFalse(ended_called);

    canceller->cancel();
}

- (void)test_input_touch_events {
    auto const manager = event_manager::make_shared();
    manager_for_view_ptr const manager_for_view = manager;

    bool began_called = false;
    bool ended_called = false;

    auto canceller = manager
                         ->observe([&began_called, &ended_called, self](std::shared_ptr<event> const &event) {
                             XCTAssertEqual(event->type(), event_type::touch);

                             if (event->get<touch>().touch_id == touch_id{.kind = touch_kind::touch, .identifier = 1}) {
                                 if (event->phase() == event_phase::began) {
                                     began_called = true;
                                 } else if (event->phase() == event_phase::ended) {
                                     ended_called = true;
                                 }
                             }
                         })
                         .end();

    manager_for_view->input_touch_event(event_phase::ended,
                                        touch_event{{.kind = touch_kind::touch, .identifier = 1}, {.v = 0.0f}, 0.0});

    XCTAssertFalse(began_called);
    XCTAssertFalse(ended_called);

    manager_for_view->input_touch_event(event_phase::began,
                                        touch_event{{.kind = touch_kind::touch, .identifier = 2}, {.v = 0.0f}, 0.0});

    XCTAssertFalse(began_called);
    XCTAssertFalse(ended_called);

    manager_for_view->input_touch_event(event_phase::ended,
                                        touch_event{{.kind = touch_kind::touch, .identifier = 1}, {.v = 0.0f}, 0.0});

    XCTAssertFalse(began_called);
    XCTAssertFalse(ended_called);

    manager_for_view->input_touch_event(event_phase::began,
                                        touch_event{{.kind = touch_kind::touch, .identifier = 1}, {.v = 0.0f}, 0.0});

    XCTAssertTrue(began_called);
    began_called = false;
    XCTAssertFalse(ended_called);

    manager_for_view->input_touch_event(event_phase::began,
                                        touch_event{{.kind = touch_kind::touch, .identifier = 1}, {.v = 0.0f}, 0.0});

    XCTAssertFalse(began_called);
    XCTAssertFalse(ended_called);

    manager_for_view->input_touch_event(event_phase::ended,
                                        touch_event{{.kind = touch_kind::touch, .identifier = 1}, {.v = 0.0f}, 0.0});

    XCTAssertFalse(began_called);
    XCTAssertTrue(ended_called);
    ended_called = false;

    manager_for_view->input_touch_event(event_phase::ended,
                                        touch_event{{.kind = touch_kind::touch, .identifier = 1}, {.v = 0.0f}, 0.0});

    XCTAssertFalse(began_called);
    XCTAssertFalse(ended_called);

    canceller->cancel();
}

- (void)test_input_key_events {
    auto const manager = event_manager::make_shared();
    manager_for_view_ptr const manager_for_view = manager;

    bool began_called = false;
    bool ended_called = false;

    auto canceller = manager
                         ->observe([&began_called, &ended_called, self](std::shared_ptr<event> const &event) {
                             XCTAssertEqual(event->type(), event_type::key);

                             if (event->get<key>().key_code == 1) {
                                 if (event->phase() == event_phase::began) {
                                     began_called = true;
                                 } else if (event->phase() == event_phase::ended) {
                                     ended_called = true;
                                 }
                             }
                         })
                         .end();

    manager_for_view->input_key_event(event_phase::ended, key_event{1, "", "", 0.0});

    XCTAssertFalse(began_called);
    XCTAssertFalse(ended_called);

    manager_for_view->input_key_event(event_phase::began, key_event{2, "", "", 0.0});

    XCTAssertFalse(began_called);
    XCTAssertFalse(ended_called);

    manager_for_view->input_key_event(event_phase::ended, key_event{1, "", "", 0.0});

    XCTAssertFalse(began_called);
    XCTAssertFalse(ended_called);

    manager_for_view->input_key_event(event_phase::began, key_event{1, "", "", 0.0});

    XCTAssertTrue(began_called);
    began_called = false;
    XCTAssertFalse(ended_called);

    manager_for_view->input_key_event(event_phase::began, key_event{1, "", "", 0.0});

    XCTAssertTrue(ended_called);
    XCTAssertTrue(began_called);
    began_called = false;
    ended_called = false;

    manager_for_view->input_key_event(event_phase::ended, key_event{1, "", "", 0.0});

    XCTAssertFalse(began_called);
    XCTAssertTrue(ended_called);
    ended_called = false;

    manager_for_view->input_key_event(event_phase::ended, key_event{1, "", "", 0.0});

    XCTAssertFalse(began_called);
    XCTAssertFalse(ended_called);

    canceller->cancel();
}

- (void)test_input_modifier_events {
    auto const manager = event_manager::make_shared();
    manager_for_view_ptr const manager_for_view = manager;

    bool began_called = false;
    bool ended_called = false;

    auto canceller = manager
                         ->observe([&began_called, &ended_called, self](std::shared_ptr<event> const &event) {
                             XCTAssertEqual(event->type(), event_type::modifier);

                             if (event->get<modifier>().flag == modifier_flags::alpha_shift) {
                                 if (event->phase() == event_phase::began) {
                                     began_called = true;
                                 } else if (event->phase() == event_phase::ended) {
                                     ended_called = true;
                                 }
                             }
                         })
                         .end();

    manager_for_view->input_modifier_event(modifier_flags(0), 0.0);

    XCTAssertFalse(began_called);
    XCTAssertFalse(ended_called);

    manager_for_view->input_modifier_event(modifier_flags::command, 0.0);

    XCTAssertFalse(began_called);
    XCTAssertFalse(ended_called);

    manager_for_view->input_modifier_event(modifier_flags(0), 0.0);

    XCTAssertFalse(began_called);
    XCTAssertFalse(ended_called);

    manager_for_view->input_modifier_event(modifier_flags::alpha_shift, 0.0);

    XCTAssertTrue(began_called);
    began_called = false;
    XCTAssertFalse(ended_called);

    manager_for_view->input_modifier_event(modifier_flags::alpha_shift, 0.0);

    XCTAssertFalse(began_called);
    XCTAssertFalse(ended_called);

    manager_for_view->input_modifier_event(modifier_flags(0), 0.0);

    XCTAssertFalse(began_called);
    XCTAssertTrue(ended_called);
    ended_called = false;

    manager_for_view->input_modifier_event(modifier_flags(0), 0.0);

    XCTAssertFalse(began_called);
    XCTAssertFalse(ended_called);

    manager_for_view->input_modifier_event(modifier_flags(modifier_flags::alpha_shift | modifier_flags::command), 0.0);

    XCTAssertTrue(began_called);
    began_called = false;
    XCTAssertFalse(ended_called);

    manager_for_view->input_modifier_event(modifier_flags::command, 0.0);

    XCTAssertFalse(began_called);
    XCTAssertTrue(ended_called);
    ended_called = false;

    canceller->cancel();
}

- (void)test_observe_input_cursor_events {
    auto const manager = event_manager::make_shared();
    manager_for_view_ptr const manager_for_view = manager;

    bool began_called = false;
    bool ended_called = false;

    auto canceller = manager
                         ->observe([&began_called, &ended_called, self](std::shared_ptr<event> const &event) {
                             if (event->type() == event_type::cursor) {
                                 if (event->phase() == event_phase::began) {
                                     began_called = true;
                                 } else if (event->phase() == event_phase::ended) {
                                     ended_called = true;
                                 }
                             }
                         })
                         .end();

    manager_for_view->input_cursor_event(cursor_phase::began, cursor_event{{.v = 2.0f}, 0.0});  // outsize of view

    XCTAssertFalse(began_called);
    XCTAssertFalse(ended_called);

    manager_for_view->input_cursor_event(cursor_phase::began, cursor_event{{.v = 0.0f}, 0.0});  // inside of view

    XCTAssertTrue(began_called);
    began_called = false;
    XCTAssertFalse(ended_called);

    manager_for_view->input_cursor_event(cursor_phase::began, cursor_event{{.v = 0.0f}, 0.0});  // inside of view

    XCTAssertFalse(began_called);
    XCTAssertFalse(ended_called);

    manager_for_view->input_cursor_event(cursor_phase::began, cursor_event{{.v = -2.0f}, 0.0});  // outsize of view

    XCTAssertFalse(began_called);
    XCTAssertTrue(ended_called);
    ended_called = false;

    manager_for_view->input_cursor_event(cursor_phase::began, cursor_event{{.v = -2.0f}, 0.0});  // outsize of view

    XCTAssertFalse(began_called);
    XCTAssertFalse(ended_called);

    canceller->cancel();
}

- (void)test_observe_input_touch_events {
    auto const manager = event_manager::make_shared();
    manager_for_view_ptr const manager_for_view = manager;

    bool began_called = false;
    bool ended_called = false;

    auto canceller =
        manager
            ->observe([&began_called, &ended_called, self](std::shared_ptr<event> const &event) {
                if (event->type() == event_type::touch) {
                    if (event->get<touch>().touch_id == touch_id{.kind = touch_kind::touch, .identifier = 1}) {
                        if (event->phase() == event_phase::began) {
                            began_called = true;
                        } else if (event->phase() == event_phase::ended) {
                            ended_called = true;
                        }
                    }
                }
            })
            .end();

    manager_for_view->input_touch_event(event_phase::ended,
                                        touch_event{{.kind = touch_kind::touch, .identifier = 1}, {.v = 0.0f}, 0.0});

    XCTAssertFalse(began_called);
    XCTAssertFalse(ended_called);

    manager_for_view->input_touch_event(event_phase::began,
                                        touch_event{{.kind = touch_kind::touch, .identifier = 2}, {.v = 0.0f}, 0.0});

    XCTAssertFalse(began_called);
    XCTAssertFalse(ended_called);

    manager_for_view->input_touch_event(event_phase::ended,
                                        touch_event{{.kind = touch_kind::touch, .identifier = 1}, {.v = 0.0f}, 0.0});

    XCTAssertFalse(began_called);
    XCTAssertFalse(ended_called);

    manager_for_view->input_touch_event(event_phase::began,
                                        touch_event{{.kind = touch_kind::touch, .identifier = 1}, {.v = 0.0f}, 0.0});

    XCTAssertTrue(began_called);
    began_called = false;
    XCTAssertFalse(ended_called);

    manager_for_view->input_touch_event(event_phase::began,
                                        touch_event{{.kind = touch_kind::touch, .identifier = 1}, {.v = 0.0f}, 0.0});

    XCTAssertFalse(began_called);
    XCTAssertFalse(ended_called);

    manager_for_view->input_touch_event(event_phase::ended,
                                        touch_event{{.kind = touch_kind::touch, .identifier = 1}, {.v = 0.0f}, 0.0});

    XCTAssertFalse(began_called);
    XCTAssertTrue(ended_called);
    ended_called = false;

    manager_for_view->input_touch_event(event_phase::ended,
                                        touch_event{{.kind = touch_kind::touch, .identifier = 1}, {.v = 0.0f}, 0.0});

    XCTAssertFalse(began_called);
    XCTAssertFalse(ended_called);

    canceller->cancel();
}

- (void)test_observe_input_key_events {
    auto const manager = event_manager::make_shared();
    manager_for_view_ptr const manager_for_view = manager;

    bool began_called = false;
    bool ended_called = false;

    auto canceller = manager
                         ->observe([&began_called, &ended_called, self](std::shared_ptr<event> const &event) {
                             if (event->type() == event_type::key) {
                                 if (event->get<key>().key_code == 1) {
                                     if (event->phase() == event_phase::began) {
                                         began_called = true;
                                     } else if (event->phase() == event_phase::ended) {
                                         ended_called = true;
                                     }
                                 }
                             }
                         })
                         .end();

    manager_for_view->input_key_event(event_phase::ended, key_event{1, "", "", 0.0});

    XCTAssertFalse(began_called);
    XCTAssertFalse(ended_called);

    manager_for_view->input_key_event(event_phase::began, key_event{2, "", "", 0.0});

    XCTAssertFalse(began_called);
    XCTAssertFalse(ended_called);

    manager_for_view->input_key_event(event_phase::ended, key_event{1, "", "", 0.0});

    XCTAssertFalse(began_called);
    XCTAssertFalse(ended_called);

    manager_for_view->input_key_event(event_phase::began, key_event{1, "", "", 0.0});

    XCTAssertTrue(began_called);
    began_called = false;
    XCTAssertFalse(ended_called);

    manager_for_view->input_key_event(event_phase::began, key_event{1, "", "", 0.0});

    XCTAssertTrue(began_called);
    XCTAssertTrue(ended_called);
    began_called = false;
    ended_called = false;

    manager_for_view->input_key_event(event_phase::ended, key_event{1, "", "", 0.0});

    XCTAssertFalse(began_called);
    XCTAssertTrue(ended_called);
    ended_called = false;

    manager_for_view->input_key_event(event_phase::ended, key_event{1, "", "", 0.0});

    XCTAssertFalse(began_called);
    XCTAssertFalse(ended_called);

    canceller->cancel();
}

- (void)test_observe_input_modifier_events {
    auto const manager = event_manager::make_shared();
    manager_for_view_ptr const manager_for_view = manager;

    bool began_called = false;
    bool ended_called = false;

    auto canceller = manager
                         ->observe([&began_called, &ended_called, self](std::shared_ptr<event> const &event) {
                             if (event->type() == event_type::modifier) {
                                 if (event->get<modifier>().flag == modifier_flags::alpha_shift) {
                                     if (event->phase() == event_phase::began) {
                                         began_called = true;
                                     } else if (event->phase() == event_phase::ended) {
                                         ended_called = true;
                                     }
                                 }
                             }
                         })
                         .end();

    manager_for_view->input_modifier_event(modifier_flags(0), 0.0);

    XCTAssertFalse(began_called);
    XCTAssertFalse(ended_called);

    manager_for_view->input_modifier_event(modifier_flags::command, 0.0);

    XCTAssertFalse(began_called);
    XCTAssertFalse(ended_called);

    manager_for_view->input_modifier_event(modifier_flags(0), 0.0);

    XCTAssertFalse(began_called);
    XCTAssertFalse(ended_called);

    manager_for_view->input_modifier_event(modifier_flags::alpha_shift, 0.0);

    XCTAssertTrue(began_called);
    began_called = false;
    XCTAssertFalse(ended_called);

    manager_for_view->input_modifier_event(modifier_flags::alpha_shift, 0.0);

    XCTAssertFalse(began_called);
    XCTAssertFalse(ended_called);

    manager_for_view->input_modifier_event(modifier_flags(0), 0.0);

    XCTAssertFalse(began_called);
    XCTAssertTrue(ended_called);
    ended_called = false;

    manager_for_view->input_modifier_event(modifier_flags(0), 0.0);

    XCTAssertFalse(began_called);
    XCTAssertFalse(ended_called);

    manager_for_view->input_modifier_event(modifier_flags(modifier_flags::alpha_shift | modifier_flags::command), 0.0);

    XCTAssertTrue(began_called);
    began_called = false;
    XCTAssertFalse(ended_called);

    manager_for_view->input_modifier_event(modifier_flags::command, 0.0);

    XCTAssertFalse(began_called);
    XCTAssertTrue(ended_called);
    ended_called = false;

    canceller->cancel();
}

- (void)test_observe {
    auto const manager = event_manager::make_shared();
    manager_for_view_ptr const manager_for_view = manager;

    std::vector<std::shared_ptr<event>> called_events;

    auto clear = [&called_events]() { called_events.clear(); };

    auto canceller =
        manager->observe([&called_events](std::shared_ptr<event> const &event) { called_events.push_back(event); })
            .end();

    manager_for_view->input_cursor_event(cursor_phase::began, cursor_event{{.v = 0.0f}, 0.0});

    XCTAssertEqual(called_events.size(), 1);
    XCTAssertEqual(called_events.at(0)->type(), event_type::cursor);
    XCTAssertTrue(called_events.at(0)->type_info() == typeid(cursor));

    clear();

    manager_for_view->input_touch_event(event_phase::began,
                                        touch_event{{.kind = touch_kind::touch, .identifier = 1}, {.v = 0.0f}, 0.0});

    XCTAssertEqual(called_events.size(), 1);
    XCTAssertEqual(called_events.at(0)->type(), event_type::touch);
    XCTAssertTrue(called_events.at(0)->type_info() == typeid(touch));

    clear();

    manager_for_view->input_key_event(event_phase::began, key_event{1, "", "", 0.0});

    XCTAssertEqual(called_events.size(), 1);
    XCTAssertEqual(called_events.at(0)->type(), event_type::key);
    XCTAssertTrue(called_events.at(0)->type_info() == typeid(key));

    clear();

    manager_for_view->input_modifier_event(modifier_flags::alpha_shift, 0.0);

    XCTAssertEqual(called_events.size(), 1);
    XCTAssertEqual(called_events.at(0)->type(), event_type::modifier);
    XCTAssertTrue(called_events.at(0)->type_info() == typeid(modifier));

    canceller->cancel();
}

- (void)test_is_equal_touch_id {
    touch_id const id_mouse_1a{touch_kind::mouse, 1};
    touch_id const id_mouse_1b{touch_kind::mouse, 1};
    touch_id const id_mouse_2{touch_kind::mouse, 2};
    touch_id const id_touch_1{touch_kind::touch, 1};

    XCTAssertTrue(id_mouse_1a == id_mouse_1a);
    XCTAssertTrue(id_mouse_1a == id_mouse_1b);
    XCTAssertFalse(id_mouse_1a == id_mouse_2);
    XCTAssertFalse(id_mouse_1a == id_touch_1);

    XCTAssertFalse(id_mouse_1a != id_mouse_1a);
    XCTAssertFalse(id_mouse_1a != id_mouse_1b);
    XCTAssertTrue(id_mouse_1a != id_mouse_2);
    XCTAssertTrue(id_mouse_1a != id_touch_1);
}

- (void)test_is_less_than_touch_id {
    touch_id const id_mouse_1a{touch_kind::mouse, 1};
    touch_id const id_mouse_1b{touch_kind::mouse, 1};
    touch_id const id_mouse_2{touch_kind::mouse, 2};
    touch_id const id_touch_1{touch_kind::touch, 1};
    touch_id const id_touch_2{touch_kind::touch, 2};

    XCTAssertFalse(id_mouse_1a < id_mouse_1b);
    XCTAssertTrue(id_mouse_1a < id_mouse_2);
    XCTAssertFalse(id_mouse_2 < id_mouse_1a);
    XCTAssertFalse(id_mouse_1a < id_touch_1);
    XCTAssertFalse(id_mouse_1a < id_touch_2);
    XCTAssertTrue(id_touch_1 < id_mouse_1a);
    XCTAssertTrue(id_touch_1 < id_mouse_2);
    XCTAssertTrue(id_touch_1 < id_touch_2);
    XCTAssertFalse(id_touch_2 < id_touch_1);
}

@end
