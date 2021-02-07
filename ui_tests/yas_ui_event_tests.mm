//
//  yas_ui_event_tests.mm
//

#import <XCTest/XCTest.h>
#import <ui/ui.h>
#import <sstream>

using namespace yas;

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
    XCTAssertEqual(to_string(ui::event_phase::none), "none");
    XCTAssertEqual(to_string(ui::event_phase::began), "began");
    XCTAssertEqual(to_string(ui::event_phase::stationary), "stationary");
    XCTAssertEqual(to_string(ui::event_phase::changed), "changed");
    XCTAssertEqual(to_string(ui::event_phase::ended), "ended");
    XCTAssertEqual(to_string(ui::event_phase::canceled), "canceled");
    XCTAssertEqual(to_string(ui::event_phase::may_begin), "may_begin");
}

- (void)test_modifier_flags_to_string {
    XCTAssertEqual(to_string(ui::modifier_flags::alpha_shift), "alpha_shift");
    XCTAssertEqual(to_string(ui::modifier_flags::shift), "shift");
    XCTAssertEqual(to_string(ui::modifier_flags::control), "control");
    XCTAssertEqual(to_string(ui::modifier_flags::alternate), "alternate");
    XCTAssertEqual(to_string(ui::modifier_flags::command), "command");
    XCTAssertEqual(to_string(ui::modifier_flags::numeric_pad), "numeric_pad");
    XCTAssertEqual(to_string(ui::modifier_flags::help), "help");
    XCTAssertEqual(to_string(ui::modifier_flags::function), "function");
}

- (void)test_event_manager_method_to_string {
    XCTAssertEqual(to_string(ui::event_manager::method::cursor_changed), "cursor_changed");
    XCTAssertEqual(to_string(ui::event_manager::method::touch_changed), "touch_changed");
    XCTAssertEqual(to_string(ui::event_manager::method::key_changed), "key_changed");
    XCTAssertEqual(to_string(ui::event_manager::method::modifier_changed), "modifier_changed");
}

- (void)test_event_phase_ostream {
    auto const phases = {ui::event_phase::none,     ui::event_phase::began, ui::event_phase::stationary,
                         ui::event_phase::changed,  ui::event_phase::ended, ui::event_phase::canceled,
                         ui::event_phase::may_begin};

    for (auto const &phase : phases) {
        std::ostringstream stream;
        stream << phase;
        XCTAssertEqual(stream.str(), to_string(phase));
    }
}

- (void)test_modifier_flags_ostream {
    auto const flags = {ui::modifier_flags::alpha_shift, ui::modifier_flags::shift,   ui::modifier_flags::control,
                        ui::modifier_flags::alternate,   ui::modifier_flags::command, ui::modifier_flags::numeric_pad,
                        ui::modifier_flags::help,        ui::modifier_flags::function};

    for (auto const &flag : flags) {
        std::ostringstream stream;
        stream << flag;
        XCTAssertEqual(stream.str(), to_string(flag));
    }
}

- (void)test_event_manager_method_ostream {
    auto const methods = {ui::event_manager::method::cursor_changed, ui::event_manager::method::touch_changed,
                          ui::event_manager::method::key_changed, ui::event_manager::method::modifier_changed};

    for (auto const &method : methods) {
        std::ostringstream stream;
        stream << method;
        XCTAssertEqual(stream.str(), to_string(method));
    }
}

- (void)test_create_cursor_event {
    ui::cursor_event value{{1.0f, 2.0f}, 3.0};

    XCTAssertEqual(value.position().x, 1.0f);
    XCTAssertEqual(value.position().y, 2.0f);
    XCTAssertEqual(value.timestamp(), 3.0);
}

- (void)test_create_touch_event {
    ui::touch_event value{10, {4.0f, 8.0f}, 16.0};

    XCTAssertEqual(value.identifier(), 10);
    XCTAssertEqual(value.position().x, 4.0f);
    XCTAssertEqual(value.position().y, 8.0f);
    XCTAssertEqual(value.timestamp(), 16.0);
}

- (void)test_create_key_event {
    ui::key_event value{5, "a", "B", 6.0};

    XCTAssertEqual(value.key_code(), 5);
    XCTAssertEqual(value.characters(), "a");
    XCTAssertEqual(value.raw_characters(), "B");
    XCTAssertEqual(value.timestamp(), 6.0);
}

- (void)test_create_modifier_event {
    ui::modifier_event value{ui::modifier_flags::alpha_shift, 7.0};

    XCTAssertEqual(value.flag(), ui::modifier_flags::alpha_shift);
    XCTAssertEqual(value.timestamp(), 7.0);
}

- (void)test_create_default {
    ui::cursor_event cursor_event;
    ui::touch_event touch_event;
    ui::key_event key_event;
    ui::modifier_event modifier_event;
}

- (void)test_is_equal_cursor_event {
    ui::cursor_event value1{{1.0f, 2.0f}, 5.0};
    ui::cursor_event value2{{3.0f, 4.0f}, 6.0};

    // always equal

    XCTAssertTrue(value1 == value2);
    XCTAssertFalse(value1 != value2);
}

- (void)test_is_equal_touch_event {
    ui::touch_event value1{5, {4.0f, 8.0f}, 16.0};
    ui::touch_event value2{5, {16.0f, 32.0f}, 32.0};
    ui::touch_event value3{6, {4.0f, 8.0f}, 16.0};

    // compare identifier

    XCTAssertTrue(value1 == value2);
    XCTAssertFalse(value1 == value3);

    XCTAssertFalse(value1 != value2);
    XCTAssertTrue(value1 != value3);
}

- (void)test_is_equal_key_event {
    ui::key_event value1{7, "a", "B", 9.0};
    ui::key_event value2{7, "c", "D", 10.0};
    ui::key_event value3{8, "a", "B", 9.0};

    // compare key_code

    XCTAssertTrue(value1 == value2);
    XCTAssertFalse(value1 == value3);

    XCTAssertFalse(value1 != value2);
    XCTAssertTrue(value1 != value3);
}

- (void)test_is_equal_modifier_event {
    ui::modifier_event value1{ui::modifier_flags::shift, 20.0};
    ui::modifier_event value2{ui::modifier_flags::shift, 30.0};
    ui::modifier_event value3{ui::modifier_flags::control, 20.0};

    // compare flag

    XCTAssertTrue(value1 == value2);
    XCTAssertFalse(value1 == value3);

    XCTAssertFalse(value1 != value2);
    XCTAssertTrue(value1 != value3);
}

- (void)test_create_event_of_cursor {
    auto event = ui::event::make_shared(ui::cursor_tag);

    XCTAssertTrue(event);
    XCTAssertTrue(event->type_info() == typeid(ui::cursor));
}

- (void)test_create_event_of_touch {
    auto event = ui::event::make_shared(ui::touch_tag);

    XCTAssertTrue(event);
    XCTAssertTrue(event->type_info() == typeid(ui::touch));
}

- (void)test_create_event_of_key {
    auto event = ui::event::make_shared(ui::key_tag);

    XCTAssertTrue(event);
    XCTAssertTrue(event->type_info() == typeid(ui::key));
}

- (void)test_create_event_of_modifier {
    auto event = ui::event::make_shared(ui::modifier_tag);

    XCTAssertTrue(event);
    XCTAssertTrue(event->type_info() == typeid(ui::modifier));
}

- (void)test_phase {
    auto event = ui::event::make_shared(ui::cursor_tag);

    XCTAssertEqual(event->phase(), ui::event_phase::none);

    ui::manageable_event::cast(event)->set_phase(ui::event_phase::began);

    XCTAssertEqual(event->phase(), ui::event_phase::began);
}

- (void)test_is_equal_event {
    auto cursor_event = ui::event::make_shared(ui::cursor_tag);
    auto touch_event1 = ui::event::make_shared(ui::touch_tag);
    auto touch_event2 = ui::event::make_shared(ui::touch_tag);
    auto touch_event3 = ui::event::make_shared(ui::touch_tag);

    ui::manageable_event::cast(cursor_event)->set<ui::cursor>(ui::cursor_event{{.v = 0.0f}, 10.0});
    ui::manageable_event::cast(touch_event1)->set<ui::touch>(ui::touch_event{1, {.v = 0.0f}, 10.0});
    ui::manageable_event::cast(touch_event2)->set<ui::touch>(ui::touch_event{1, {.v = 0.0f}, 11.0});
    ui::manageable_event::cast(touch_event3)->set<ui::touch>(ui::touch_event{2, {.v = 0.0f}, 12.0});

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
    auto event = ui::event::make_shared(ui::cursor_tag);

    XCTAssertTrue(typeid(event->get<ui::cursor>()) == typeid(ui::cursor_event));

    ui::manageable_event::cast(event)->set<ui::cursor>(ui::cursor_event{{0.5f, 1.5f}, 100.0});

    auto const &pos = event->get<ui::cursor>().position();
    XCTAssertEqual(pos.x, 0.5f);
    XCTAssertEqual(pos.y, 1.5f);
    auto const timestamp = event->get<ui::cursor>().timestamp();
    XCTAssertEqual(timestamp, 100.0);
}

- (void)test_touch_event_accessor {
    auto event = ui::event::make_shared(ui::touch_tag);

    XCTAssertTrue(typeid(event->get<ui::touch>()) == typeid(ui::touch_event));

    ui::manageable_event::cast(event)->set<ui::touch>(ui::touch_event{11, {2.5f, 3.5f}, 200.0});

    auto const &value = event->get<ui::touch>();
    auto const &pos = value.position();
    XCTAssertEqual(value.identifier(), 11);
    XCTAssertEqual(pos.x, 2.5f);
    XCTAssertEqual(pos.y, 3.5f);
    auto const timestamp = event->get<ui::touch>().timestamp();
    XCTAssertEqual(timestamp, 200.0);
}

- (void)test_key_event_accessor {
    auto event = ui::event::make_shared(ui::key_tag);

    XCTAssertTrue(typeid(event->get<ui::key>()) == typeid(ui::key_event));

    ui::manageable_event::cast(event)->set<ui::key>(ui::key_event{23, "4", "5", 300.0});

    auto const &value = event->get<ui::key>();
    XCTAssertEqual(value.key_code(), 23);
    XCTAssertEqual(value.characters(), "4");
    XCTAssertEqual(value.raw_characters(), "5");
    auto const timestamp = event->get<ui::key>().timestamp();
    XCTAssertEqual(timestamp, 300.0);
}

- (void)test_modifier_event_accessor {
    auto event = ui::event::make_shared(ui::modifier_tag);

    XCTAssertTrue(typeid(event->get<ui::modifier>()) == typeid(ui::modifier_event));

    ui::manageable_event::cast(event)->set<ui::modifier>(ui::modifier_event{ui::modifier_flags::command, 400.0});

    auto const &value = event->get<ui::modifier>();
    XCTAssertEqual(value.flag(), ui::modifier_flags::command);
    auto const timestamp = event->get<ui::modifier>().timestamp();
    XCTAssertEqual(timestamp, 400.0);
}

- (void)test_create_manager {
    auto manager = ui::event_manager::make_shared();

    XCTAssertTrue(manager);
    XCTAssertTrue(ui::event_inputtable::cast(manager));
}

- (void)test_input_cursor_event_began {
    auto manager = ui::event_manager::make_shared();

    bool called = false;

    auto canceller = manager->observe([&called, self](auto const &context) {
        auto const &method = context.method;
        ui::event_ptr const &event = context.event;

        XCTAssertEqual(method, ui::event_manager::method::cursor_changed);

        auto const &value = event->get<ui::cursor>();
        XCTAssertEqual(value.position().x, 0.25f);
        XCTAssertEqual(value.position().y, 0.125f);
        XCTAssertEqual(value.timestamp(), 101.0);

        called = true;
    });

    ui::event_inputtable::cast(manager)->input_cursor_event(ui::cursor_event{{0.25f, 0.125f}, 101.0});

    XCTAssertTrue(called);
}

- (void)test_input_touch_event_began {
    auto manager = ui::event_manager::make_shared();

    bool called = false;

    auto canceller = manager->observe([&called, self](auto const &context) {
        auto const &method = context.method;
        ui::event_ptr const &event = context.event;

        XCTAssertEqual(method, ui::event_manager::method::touch_changed);

        auto const &value = event->get<ui::touch>();
        XCTAssertEqual(value.identifier(), 100);
        XCTAssertEqual(value.position().x, 256.0f);
        XCTAssertEqual(value.position().y, 512.0f);
        XCTAssertEqual(value.timestamp(), 201.0);

        called = true;
    });

    ui::event_inputtable::cast(manager)->input_touch_event(ui::event_phase::began,
                                                           ui::touch_event{100, {256.0f, 512.0f}, 201.0});

    XCTAssertTrue(called);
}

- (void)test_input_key_event_began {
    auto manager = ui::event_manager::make_shared();

    bool called = false;

    auto canceller = manager->observe([&called, self](auto const &context) {
        auto const &method = context.method;
        ui::event_ptr const &event = context.event;

        XCTAssertEqual(method, ui::event_manager::method::key_changed);

        auto const &value = event->get<ui::key>();
        XCTAssertEqual(value.key_code(), 200);
        XCTAssertEqual(value.characters(), "xyz");
        XCTAssertEqual(value.raw_characters(), "uvw");
        XCTAssertEqual(value.timestamp(), 301.0);

        called = true;
    });

    ui::event_inputtable::cast(manager)->input_key_event(ui::event_phase::began,
                                                         ui::key_event{200, "xyz", "uvw", 301.0});

    XCTAssertTrue(called);
}

- (void)test_input_modifier_event_began {
    auto manager = ui::event_manager::make_shared();

    bool alt_called = false;
    bool func_called = false;

    auto canceller = manager->observe([&alt_called, &func_called, self](auto const &context) {
        auto const &method = context.method;
        ui::event_ptr const &event = context.event;

        XCTAssertEqual(method, ui::event_manager::method::modifier_changed);

        auto const &value = event->get<ui::modifier>();

        if (value.flag() == ui::modifier_flags::alternate) {
            alt_called = true;
        }

        if (value.flag() == ui::modifier_flags::function) {
            func_called = true;
        }
    });

    ui::event_inputtable::cast(manager)->input_modifier_event(
        ui::modifier_flags(ui::modifier_flags::alternate | ui::modifier_flags::function), 0.0);

    XCTAssertTrue(alt_called);
    XCTAssertTrue(func_called);
}

- (void)test_input_cursor_events {
    auto manager = ui::event_manager::make_shared();

    bool began_called = false;
    bool ended_called = false;

    auto canceller = manager->observe([&began_called, &ended_called, self](auto const &context) {
        auto const &method = context.method;
        ui::event_ptr const &event = context.event;

        XCTAssertEqual(method, ui::event_manager::method::cursor_changed);

        if (event->phase() == ui::event_phase::began) {
            began_called = true;
        } else if (event->phase() == ui::event_phase::ended) {
            ended_called = true;
        }
    });

    ui::event_inputtable::cast(manager)->input_cursor_event(ui::cursor_event{{.v = 2.0f}, 0.0});  // outsize of view

    XCTAssertFalse(began_called);
    XCTAssertFalse(ended_called);

    ui::event_inputtable::cast(manager)->input_cursor_event(ui::cursor_event{{.v = 0.0f}, 0.0});  // inside of view

    XCTAssertTrue(began_called);
    began_called = false;
    XCTAssertFalse(ended_called);

    ui::event_inputtable::cast(manager)->input_cursor_event(ui::cursor_event{{.v = 0.0f}, 0.0});  // inside of view

    XCTAssertFalse(began_called);
    XCTAssertFalse(ended_called);

    ui::event_inputtable::cast(manager)->input_cursor_event(ui::cursor_event{{.v = -2.0f}, 0.0});  // outsize of view

    XCTAssertFalse(began_called);
    XCTAssertTrue(ended_called);
    ended_called = false;

    ui::event_inputtable::cast(manager)->input_cursor_event(ui::cursor_event{{.v = -2.0f}, 0.0});  // outsize of view

    XCTAssertFalse(began_called);
    XCTAssertFalse(ended_called);
}

- (void)test_input_touch_events {
    auto manager = ui::event_manager::make_shared();

    bool began_called = false;
    bool ended_called = false;

    auto canceller = manager->observe([&began_called, &ended_called, self](auto const &context) {
        auto const &method = context.method;
        ui::event_ptr const &event = context.event;

        XCTAssertEqual(method, ui::event_manager::method::touch_changed);

        if (event->get<ui::touch>().identifier() == 1) {
            if (event->phase() == ui::event_phase::began) {
                began_called = true;
            } else if (event->phase() == ui::event_phase::ended) {
                ended_called = true;
            }
        }
    });

    ui::event_inputtable::cast(manager)->input_touch_event(ui::event_phase::ended,
                                                           ui::touch_event{1, {.v = 0.0f}, 0.0});

    XCTAssertFalse(began_called);
    XCTAssertFalse(ended_called);

    ui::event_inputtable::cast(manager)->input_touch_event(ui::event_phase::began,
                                                           ui::touch_event{2, {.v = 0.0f}, 0.0});

    XCTAssertFalse(began_called);
    XCTAssertFalse(ended_called);

    ui::event_inputtable::cast(manager)->input_touch_event(ui::event_phase::ended,
                                                           ui::touch_event{1, {.v = 0.0f}, 0.0});

    XCTAssertFalse(began_called);
    XCTAssertFalse(ended_called);

    ui::event_inputtable::cast(manager)->input_touch_event(ui::event_phase::began,
                                                           ui::touch_event{1, {.v = 0.0f}, 0.0});

    XCTAssertTrue(began_called);
    began_called = false;
    XCTAssertFalse(ended_called);

    ui::event_inputtable::cast(manager)->input_touch_event(ui::event_phase::began,
                                                           ui::touch_event{1, {.v = 0.0f}, 0.0});

    XCTAssertFalse(began_called);
    XCTAssertFalse(ended_called);

    ui::event_inputtable::cast(manager)->input_touch_event(ui::event_phase::ended,
                                                           ui::touch_event{1, {.v = 0.0f}, 0.0});

    XCTAssertFalse(began_called);
    XCTAssertTrue(ended_called);
    ended_called = false;

    ui::event_inputtable::cast(manager)->input_touch_event(ui::event_phase::ended,
                                                           ui::touch_event{1, {.v = 0.0f}, 0.0});

    XCTAssertFalse(began_called);
    XCTAssertFalse(ended_called);
}

- (void)test_input_key_events {
    auto manager = ui::event_manager::make_shared();

    bool began_called = false;
    bool ended_called = false;

    auto canceller = manager->observe([&began_called, &ended_called, self](auto const &context) {
        auto const &method = context.method;
        ui::event_ptr const &event = context.event;

        XCTAssertEqual(method, ui::event_manager::method::key_changed);

        if (event->get<ui::key>().key_code() == 1) {
            if (event->phase() == ui::event_phase::began) {
                began_called = true;
            } else if (event->phase() == ui::event_phase::ended) {
                ended_called = true;
            }
        }
    });

    ui::event_inputtable::cast(manager)->input_key_event(ui::event_phase::ended, ui::key_event{1, "", "", 0.0});

    XCTAssertFalse(began_called);
    XCTAssertFalse(ended_called);

    ui::event_inputtable::cast(manager)->input_key_event(ui::event_phase::began, ui::key_event{2, "", "", 0.0});

    XCTAssertFalse(began_called);
    XCTAssertFalse(ended_called);

    ui::event_inputtable::cast(manager)->input_key_event(ui::event_phase::ended, ui::key_event{1, "", "", 0.0});

    XCTAssertFalse(began_called);
    XCTAssertFalse(ended_called);

    ui::event_inputtable::cast(manager)->input_key_event(ui::event_phase::began, ui::key_event{1, "", "", 0.0});

    XCTAssertTrue(began_called);
    began_called = false;
    XCTAssertFalse(ended_called);

    ui::event_inputtable::cast(manager)->input_key_event(ui::event_phase::began, ui::key_event{1, "", "", 0.0});

    XCTAssertFalse(began_called);
    XCTAssertFalse(ended_called);

    ui::event_inputtable::cast(manager)->input_key_event(ui::event_phase::ended, ui::key_event{1, "", "", 0.0});

    XCTAssertFalse(began_called);
    XCTAssertTrue(ended_called);
    ended_called = false;

    ui::event_inputtable::cast(manager)->input_key_event(ui::event_phase::ended, ui::key_event{1, "", "", 0.0});

    XCTAssertFalse(began_called);
    XCTAssertFalse(ended_called);
}

- (void)test_input_modifier_events {
    auto manager = ui::event_manager::make_shared();

    bool began_called = false;
    bool ended_called = false;

    auto canceller = manager->observe([&began_called, &ended_called, self](auto const &context) {
        auto const &method = context.method;
        ui::event_ptr const &event = context.event;

        XCTAssertEqual(method, ui::event_manager::method::modifier_changed);

        if (event->get<ui::modifier>().flag() == ui::modifier_flags::alpha_shift) {
            if (event->phase() == ui::event_phase::began) {
                began_called = true;
            } else if (event->phase() == ui::event_phase::ended) {
                ended_called = true;
            }
        }
    });

    ui::event_inputtable::cast(manager)->input_modifier_event(ui::modifier_flags(0), 0.0);

    XCTAssertFalse(began_called);
    XCTAssertFalse(ended_called);

    ui::event_inputtable::cast(manager)->input_modifier_event(ui::modifier_flags::command, 0.0);

    XCTAssertFalse(began_called);
    XCTAssertFalse(ended_called);

    ui::event_inputtable::cast(manager)->input_modifier_event(ui::modifier_flags(0), 0.0);

    XCTAssertFalse(began_called);
    XCTAssertFalse(ended_called);

    ui::event_inputtable::cast(manager)->input_modifier_event(ui::modifier_flags::alpha_shift, 0.0);

    XCTAssertTrue(began_called);
    began_called = false;
    XCTAssertFalse(ended_called);

    ui::event_inputtable::cast(manager)->input_modifier_event(ui::modifier_flags::alpha_shift, 0.0);

    XCTAssertFalse(began_called);
    XCTAssertFalse(ended_called);

    ui::event_inputtable::cast(manager)->input_modifier_event(ui::modifier_flags(0), 0.0);

    XCTAssertFalse(began_called);
    XCTAssertTrue(ended_called);
    ended_called = false;

    ui::event_inputtable::cast(manager)->input_modifier_event(ui::modifier_flags(0), 0.0);

    XCTAssertFalse(began_called);
    XCTAssertFalse(ended_called);

    ui::event_inputtable::cast(manager)->input_modifier_event(
        ui::modifier_flags(ui::modifier_flags::alpha_shift | ui::modifier_flags::command), 0.0);

    XCTAssertTrue(began_called);
    began_called = false;
    XCTAssertFalse(ended_called);

    ui::event_inputtable::cast(manager)->input_modifier_event(ui::modifier_flags::command, 0.0);

    XCTAssertFalse(began_called);
    XCTAssertTrue(ended_called);
    ended_called = false;
}

- (void)test_chain_input_cursor_events {
    auto manager = ui::event_manager::make_shared();

    bool began_called = false;
    bool ended_called = false;

    auto canceller = manager->observe([&began_called, &ended_called, self](auto const &context) {
        if (context.method == ui::event_manager::method::cursor_changed) {
            ui::event_ptr const &event = context.event;
            if (event->phase() == ui::event_phase::began) {
                began_called = true;
            } else if (event->phase() == ui::event_phase::ended) {
                ended_called = true;
            }
        }
    });

    ui::event_inputtable::cast(manager)->input_cursor_event(ui::cursor_event{{.v = 2.0f}, 0.0});  // outsize of view

    XCTAssertFalse(began_called);
    XCTAssertFalse(ended_called);

    ui::event_inputtable::cast(manager)->input_cursor_event(ui::cursor_event{{.v = 0.0f}, 0.0});  // inside of view

    XCTAssertTrue(began_called);
    began_called = false;
    XCTAssertFalse(ended_called);

    ui::event_inputtable::cast(manager)->input_cursor_event(ui::cursor_event{{.v = 0.0f}, 0.0});  // inside of view

    XCTAssertFalse(began_called);
    XCTAssertFalse(ended_called);

    ui::event_inputtable::cast(manager)->input_cursor_event(ui::cursor_event{{.v = -2.0f}, 0.0});  // outsize of view

    XCTAssertFalse(began_called);
    XCTAssertTrue(ended_called);
    ended_called = false;

    ui::event_inputtable::cast(manager)->input_cursor_event(ui::cursor_event{{.v = -2.0f}, 0.0});  // outsize of view

    XCTAssertFalse(began_called);
    XCTAssertFalse(ended_called);
}

- (void)test_chain_input_touch_events {
    auto manager = ui::event_manager::make_shared();

    bool began_called = false;
    bool ended_called = false;

    auto canceller = manager->observe([&began_called, &ended_called, self](auto const &context) {
        if (context.method == ui::event_manager::method::touch_changed) {
            ui::event_ptr const &event = context.event;
            if (event->get<ui::touch>().identifier() == 1) {
                if (event->phase() == ui::event_phase::began) {
                    began_called = true;
                } else if (event->phase() == ui::event_phase::ended) {
                    ended_called = true;
                }
            }
        }
    });

    ui::event_inputtable::cast(manager)->input_touch_event(ui::event_phase::ended,
                                                           ui::touch_event{1, {.v = 0.0f}, 0.0});

    XCTAssertFalse(began_called);
    XCTAssertFalse(ended_called);

    ui::event_inputtable::cast(manager)->input_touch_event(ui::event_phase::began,
                                                           ui::touch_event{2, {.v = 0.0f}, 0.0});

    XCTAssertFalse(began_called);
    XCTAssertFalse(ended_called);

    ui::event_inputtable::cast(manager)->input_touch_event(ui::event_phase::ended,
                                                           ui::touch_event{1, {.v = 0.0f}, 0.0});

    XCTAssertFalse(began_called);
    XCTAssertFalse(ended_called);

    ui::event_inputtable::cast(manager)->input_touch_event(ui::event_phase::began,
                                                           ui::touch_event{1, {.v = 0.0f}, 0.0});

    XCTAssertTrue(began_called);
    began_called = false;
    XCTAssertFalse(ended_called);

    ui::event_inputtable::cast(manager)->input_touch_event(ui::event_phase::began,
                                                           ui::touch_event{1, {.v = 0.0f}, 0.0});

    XCTAssertFalse(began_called);
    XCTAssertFalse(ended_called);

    ui::event_inputtable::cast(manager)->input_touch_event(ui::event_phase::ended,
                                                           ui::touch_event{1, {.v = 0.0f}, 0.0});

    XCTAssertFalse(began_called);
    XCTAssertTrue(ended_called);
    ended_called = false;

    ui::event_inputtable::cast(manager)->input_touch_event(ui::event_phase::ended,
                                                           ui::touch_event{1, {.v = 0.0f}, 0.0});

    XCTAssertFalse(began_called);
    XCTAssertFalse(ended_called);
}

- (void)test_chain_input_key_events {
    auto manager = ui::event_manager::make_shared();

    bool began_called = false;
    bool ended_called = false;

    auto canceller = manager->observe([&began_called, &ended_called, self](auto const &context) {
        if (context.method == ui::event_manager::method::key_changed) {
            ui::event_ptr const &event = context.event;
            if (event->get<ui::key>().key_code() == 1) {
                if (event->phase() == ui::event_phase::began) {
                    began_called = true;
                } else if (event->phase() == ui::event_phase::ended) {
                    ended_called = true;
                }
            }
        }
    });

    ui::event_inputtable::cast(manager)->input_key_event(ui::event_phase::ended, ui::key_event{1, "", "", 0.0});

    XCTAssertFalse(began_called);
    XCTAssertFalse(ended_called);

    ui::event_inputtable::cast(manager)->input_key_event(ui::event_phase::began, ui::key_event{2, "", "", 0.0});

    XCTAssertFalse(began_called);
    XCTAssertFalse(ended_called);

    ui::event_inputtable::cast(manager)->input_key_event(ui::event_phase::ended, ui::key_event{1, "", "", 0.0});

    XCTAssertFalse(began_called);
    XCTAssertFalse(ended_called);

    ui::event_inputtable::cast(manager)->input_key_event(ui::event_phase::began, ui::key_event{1, "", "", 0.0});

    XCTAssertTrue(began_called);
    began_called = false;
    XCTAssertFalse(ended_called);

    ui::event_inputtable::cast(manager)->input_key_event(ui::event_phase::began, ui::key_event{1, "", "", 0.0});

    XCTAssertFalse(began_called);
    XCTAssertFalse(ended_called);

    ui::event_inputtable::cast(manager)->input_key_event(ui::event_phase::ended, ui::key_event{1, "", "", 0.0});

    XCTAssertFalse(began_called);
    XCTAssertTrue(ended_called);
    ended_called = false;

    ui::event_inputtable::cast(manager)->input_key_event(ui::event_phase::ended, ui::key_event{1, "", "", 0.0});

    XCTAssertFalse(began_called);
    XCTAssertFalse(ended_called);
}

- (void)test_chain_input_modifier_events {
    auto manager = ui::event_manager::make_shared();

    bool began_called = false;
    bool ended_called = false;

    auto canceller = manager->observe([&began_called, &ended_called, self](auto const &context) {
        if (context.method == ui::event_manager::method::modifier_changed) {
            ui::event_ptr const &event = context.event;
            if (event->get<ui::modifier>().flag() == ui::modifier_flags::alpha_shift) {
                if (event->phase() == ui::event_phase::began) {
                    began_called = true;
                } else if (event->phase() == ui::event_phase::ended) {
                    ended_called = true;
                }
            }
        }
    });

    ui::event_inputtable::cast(manager)->input_modifier_event(ui::modifier_flags(0), 0.0);

    XCTAssertFalse(began_called);
    XCTAssertFalse(ended_called);

    ui::event_inputtable::cast(manager)->input_modifier_event(ui::modifier_flags::command, 0.0);

    XCTAssertFalse(began_called);
    XCTAssertFalse(ended_called);

    ui::event_inputtable::cast(manager)->input_modifier_event(ui::modifier_flags(0), 0.0);

    XCTAssertFalse(began_called);
    XCTAssertFalse(ended_called);

    ui::event_inputtable::cast(manager)->input_modifier_event(ui::modifier_flags::alpha_shift, 0.0);

    XCTAssertTrue(began_called);
    began_called = false;
    XCTAssertFalse(ended_called);

    ui::event_inputtable::cast(manager)->input_modifier_event(ui::modifier_flags::alpha_shift, 0.0);

    XCTAssertFalse(began_called);
    XCTAssertFalse(ended_called);

    ui::event_inputtable::cast(manager)->input_modifier_event(ui::modifier_flags(0), 0.0);

    XCTAssertFalse(began_called);
    XCTAssertTrue(ended_called);
    ended_called = false;

    ui::event_inputtable::cast(manager)->input_modifier_event(ui::modifier_flags(0), 0.0);

    XCTAssertFalse(began_called);
    XCTAssertFalse(ended_called);

    ui::event_inputtable::cast(manager)->input_modifier_event(
        ui::modifier_flags(ui::modifier_flags::alpha_shift | ui::modifier_flags::command), 0.0);

    XCTAssertTrue(began_called);
    began_called = false;
    XCTAssertFalse(ended_called);

    ui::event_inputtable::cast(manager)->input_modifier_event(ui::modifier_flags::command, 0.0);

    XCTAssertFalse(began_called);
    XCTAssertTrue(ended_called);
    ended_called = false;
}

- (void)test_chain {
    auto manager = ui::event_manager::make_shared();
    std::vector<ui::event_manager::method> called_methods;
    std::vector<ui::event_ptr> called_events;

    auto clear = [&called_methods, &called_events]() {
        called_methods.clear();
        called_events.clear();
    };

    auto canceller = manager->observe([&called_methods, &called_events](auto const &context) {
        called_methods.push_back(context.method);
        called_events.push_back(context.event);
    });

    ui::event_inputtable::cast(manager)->input_cursor_event(ui::cursor_event{{.v = 0.0f}, 0.0});

    XCTAssertEqual(called_methods.size(), 1);
    XCTAssertEqual(called_events.size(), 1);
    XCTAssertEqual(called_methods.at(0), ui::event_manager::method::cursor_changed);
    XCTAssertTrue(called_events.at(0)->type_info() == typeid(ui::cursor));

    clear();

    ui::event_inputtable::cast(manager)->input_touch_event(ui::event_phase::began,
                                                           ui::touch_event{1, {.v = 0.0f}, 0.0});

    XCTAssertEqual(called_methods.size(), 1);
    XCTAssertEqual(called_events.size(), 1);
    XCTAssertEqual(called_methods.at(0), ui::event_manager::method::touch_changed);
    XCTAssertTrue(called_events.at(0)->type_info() == typeid(ui::touch));

    clear();

    ui::event_inputtable::cast(manager)->input_key_event(ui::event_phase::began, ui::key_event{1, "", "", 0.0});

    XCTAssertEqual(called_methods.size(), 1);
    XCTAssertEqual(called_events.size(), 1);
    XCTAssertEqual(called_methods.at(0), ui::event_manager::method::key_changed);
    XCTAssertTrue(called_events.at(0)->type_info() == typeid(ui::key));

    clear();

    ui::event_inputtable::cast(manager)->input_modifier_event(ui::modifier_flags::alpha_shift, 0.0);

    XCTAssertEqual(called_methods.size(), 1);
    XCTAssertEqual(called_events.size(), 1);
    XCTAssertEqual(called_methods.at(0), ui::event_manager::method::modifier_changed);
    XCTAssertTrue(called_events.at(0)->type_info() == typeid(ui::modifier));
}

@end
