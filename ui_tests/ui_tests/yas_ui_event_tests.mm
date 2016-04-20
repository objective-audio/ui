//
//  yas_ui_event_tests.mm
//

#import <XCTest/XCTest.h>
#import "yas_ui_event.h"
#import <iostream>

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

- (void)test_ostream {
    std::cout << ui::event_phase::none << std::endl;
    std::cout << ui::modifier_flags::alpha_shift << std::endl;
}

- (void)test_create_cursor_event {
    ui::cursor_event value{simd::float2{1.0f, 2.0f}};

    XCTAssertEqual(value.position().x, 1.0f);
    XCTAssertEqual(value.position().y, 2.0f);
}

- (void)test_create_touch_event {
    ui::touch_event value{10, simd::float2{4.0f, 8.0f}};

    XCTAssertEqual(value.identifier(), 10);
    XCTAssertEqual(value.position().x, 4.0f);
    XCTAssertEqual(value.position().y, 8.0f);
}

- (void)test_create_key_event {
    ui::key_event value{5, "a", "B"};

    XCTAssertEqual(value.key_code(), 5);
    XCTAssertEqual(value.characters(), "a");
    XCTAssertEqual(value.characters_ignoring_modifiers(), "B");
}

- (void)test_create_modifier_event {
    ui::modifier_event value{ui::modifier_flags::alpha_shift};

    XCTAssertEqual(value.flag(), ui::modifier_flags::alpha_shift);
}

- (void)test_create_default {
    ui::cursor_event cursor_event;
    ui::touch_event touch_event;
    ui::key_event key_event;
    ui::modifier_event modifier_event;
}

- (void)test_is_equal_cursor_event {
    ui::cursor_event value1{simd::float2{1.0f, 2.0f}};
    ui::cursor_event value2{simd::float2{3.0f, 4.0f}};

    // always equal

    XCTAssertTrue(value1 == value2);
    XCTAssertFalse(value1 != value2);
}

- (void)test_is_equal_touch_event {
    ui::touch_event value1{5, simd::float2{4.0f, 8.0f}};
    ui::touch_event value2{5, simd::float2{16.0f, 32.0f}};
    ui::touch_event value3{6, simd::float2{4.0f, 8.0f}};

    // compare identifier

    XCTAssertTrue(value1 == value2);
    XCTAssertFalse(value1 == value3);

    XCTAssertFalse(value1 != value2);
    XCTAssertTrue(value1 != value3);
}

- (void)test_is_equal_key_event {
    ui::key_event value1{7, "a", "B"};
    ui::key_event value2{7, "c", "D"};
    ui::key_event value3{8, "a", "B"};

    // compare key_code

    XCTAssertTrue(value1 == value2);
    XCTAssertFalse(value1 == value3);

    XCTAssertFalse(value1 != value2);
    XCTAssertTrue(value1 != value3);
}

- (void)test_is_equal_modifier_event {
    ui::modifier_event value1{ui::modifier_flags::shift};
    ui::modifier_event value2{ui::modifier_flags::shift};
    ui::modifier_event value3{ui::modifier_flags::control};

    // compare flag

    XCTAssertTrue(value1 == value2);
    XCTAssertFalse(value1 == value3);

    XCTAssertFalse(value1 != value2);
    XCTAssertTrue(value1 != value3);
}

- (void)test_create_null_event {
    ui::event event{nullptr};

    XCTAssertFalse(event);
}

- (void)test_create_event_of_cursor {
    ui::event event{ui::cursor_tag};

    XCTAssertTrue(event);
    XCTAssertTrue(event.type_info() == typeid(ui::cursor));
}

- (void)test_create_event_of_touch {
    ui::event event{ui::touch_tag};

    XCTAssertTrue(event);
    XCTAssertTrue(event.type_info() == typeid(ui::touch));
}

- (void)test_create_event_of_key {
    ui::event event{ui::key_tag};

    XCTAssertTrue(event);
    XCTAssertTrue(event.type_info() == typeid(ui::key));
}

- (void)test_create_event_of_modifier {
    ui::event event{ui::modifier_tag};

    XCTAssertTrue(event);
    XCTAssertTrue(event.type_info() == typeid(ui::modifier));
}

- (void)test_phase {
    ui::event event{ui::cursor_tag};

    XCTAssertEqual(event.phase(), ui::event_phase::none);

    event.manageable().set_phase(ui::event_phase::began);

    XCTAssertEqual(event.phase(), ui::event_phase::began);
}

- (void)test_is_equal_event {
    ui::event cursor_event{ui::cursor_tag};
    ui::event touch_event1{ui::touch_tag};
    ui::event touch_event2{ui::touch_tag};
    ui::event touch_event3{ui::touch_tag};

    cursor_event.manageable().set<ui::cursor>(ui::cursor_event{0.0f});
    touch_event1.manageable().set<ui::touch>(ui::touch_event{1, 0.0f});
    touch_event2.manageable().set<ui::touch>(ui::touch_event{1, 0.0f});
    touch_event3.manageable().set<ui::touch>(ui::touch_event{2, 0.0f});

    XCTAssertTrue(touch_event1 == touch_event1);
    XCTAssertTrue(touch_event1 == touch_event2);
    XCTAssertFalse(touch_event1 == touch_event3);
    XCTAssertFalse(touch_event1 == cursor_event);

    XCTAssertFalse(touch_event1 != touch_event1);
    XCTAssertFalse(touch_event1 != touch_event2);
    XCTAssertTrue(touch_event1 != touch_event3);
    XCTAssertTrue(touch_event1 != cursor_event);
}

- (void)test_cursor_event_accessor {
    ui::event event{ui::cursor_tag};

    XCTAssertTrue(typeid(event.get<ui::cursor>()) == typeid(ui::cursor_event));

    event.manageable().set<ui::cursor>(ui::cursor_event{simd::float2{0.5f, 1.5f}});

    auto const &pos = event.get<ui::cursor>().position();
    XCTAssertEqual(pos.x, 0.5f);
    XCTAssertEqual(pos.y, 1.5f);
}

- (void)test_touch_event_accessor {
    ui::event event{ui::touch_tag};

    XCTAssertTrue(typeid(event.get<ui::touch>()) == typeid(ui::touch_event));

    event.manageable().set<ui::touch>(ui::touch_event{11, simd::float2{2.5f, 3.5f}});

    auto const &value = event.get<ui::touch>();
    auto const &pos = value.position();
    XCTAssertEqual(value.identifier(), 11);
    XCTAssertEqual(pos.x, 2.5f);
    XCTAssertEqual(pos.y, 3.5f);
}

- (void)test_key_event_accessor {
    ui::event event{ui::key_tag};

    XCTAssertTrue(typeid(event.get<ui::key>()) == typeid(ui::key_event));

    event.manageable().set<ui::key>(ui::key_event{23, "4", "5"});

    auto const &value = event.get<ui::key>();
    XCTAssertEqual(value.key_code(), 23);
    XCTAssertEqual(value.characters(), "4");
    XCTAssertEqual(value.characters_ignoring_modifiers(), "5");
}

- (void)test_modifier_event_accessor {
    ui::event event{ui::modifier_tag};

    XCTAssertTrue(typeid(event.get<ui::modifier>()) == typeid(ui::modifier_event));

    event.manageable().set<ui::modifier>(ui::modifier_event{ui::modifier_flags::command});

    auto const &value = event.get<ui::modifier>();
    XCTAssertEqual(value.flag(), ui::modifier_flags::command);
}

- (void)test_create_manager {
    ui::event_manager manager;

    XCTAssertTrue(manager);
    XCTAssertTrue(manager.inputtable());
}

- (void)test_create_null_manager {
    ui::event_manager manager{nullptr};

    XCTAssertFalse(manager);
}

- (void)test_input_cursor_event_began {
    ui::event_manager manager;

    bool called = false;

    auto observer =
        manager.subject().make_wild_card_observer([&called, self](auto const &method, ui::event const &event) {
            XCTAssertEqual(method, ui::event_method::cursor_changed);

            auto const &value = event.get<ui::cursor>();
            XCTAssertEqual(value.position().x, 0.25f);
            XCTAssertEqual(value.position().y, 0.125f);

            called = true;
        });

    manager.inputtable().input_cursor_event(ui::cursor_event{simd::float2{0.25f, 0.125f}});

    XCTAssertTrue(called);
}

- (void)test_input_touch_event_began {
    ui::event_manager manager;

    bool called = false;

    auto observer =
        manager.subject().make_wild_card_observer([&called, self](auto const &method, ui::event const &event) {
            XCTAssertEqual(method, ui::event_method::touch_changed);

            auto const &value = event.get<ui::touch>();
            XCTAssertEqual(value.identifier(), 100);
            XCTAssertEqual(value.position().x, 256.0f);
            XCTAssertEqual(value.position().y, 512.0f);

            called = true;
        });

    manager.inputtable().input_touch_event(ui::event_phase::began, ui::touch_event{100, simd::float2{256.0f, 512.0f}});

    XCTAssertTrue(called);
}

- (void)test_input_key_event_began {
    ui::event_manager manager;

    bool called = false;

    auto observer =
        manager.subject().make_wild_card_observer([&called, self](auto const &method, ui::event const &event) {
            XCTAssertEqual(method, ui::event_method::key_changed);

            auto const &value = event.get<ui::key>();
            XCTAssertEqual(value.key_code(), 200);
            XCTAssertEqual(value.characters(), "xyz");
            XCTAssertEqual(value.characters_ignoring_modifiers(), "uvw");

            called = true;
        });

    manager.inputtable().input_key_event(ui::event_phase::began, ui::key_event{200, "xyz", "uvw"});

    XCTAssertTrue(called);
}

- (void)test_input_modifier_event_began {
    ui::event_manager manager;

    bool alt_called = false;
    bool func_called = false;

    auto observer = manager.subject().make_wild_card_observer(
        [&alt_called, &func_called, self](auto const &method, ui::event const &event) {
            XCTAssertEqual(method, ui::event_method::modifier_changed);

            auto const &value = event.get<ui::modifier>();

            if (value.flag() == ui::modifier_flags::alternate) {
                alt_called = true;
            }

            if (value.flag() == ui::modifier_flags::function) {
                func_called = true;
            }
        });

    manager.inputtable().input_modifier_event(
        ui::modifier_flags(ui::modifier_flags::alternate | ui::modifier_flags::function));

    XCTAssertTrue(alt_called);
    XCTAssertTrue(func_called);
}

- (void)test_input_cursor_events {
    ui::event_manager manager;

    bool began_called = false;
    bool ended_called = false;

    auto observer = manager.subject().make_wild_card_observer(
        [&began_called, &ended_called, self](auto const &method, ui::event const &event) {
            XCTAssertEqual(method, ui::event_method::cursor_changed);

            if (event.phase() == ui::event_phase::began) {
                began_called = true;
            } else if (event.phase() == ui::event_phase::ended) {
                ended_called = true;
            }
        });

    manager.inputtable().input_cursor_event(ui::cursor_event{2.0f});  // outsize of view

    XCTAssertFalse(began_called);
    XCTAssertFalse(ended_called);

    manager.inputtable().input_cursor_event(ui::cursor_event{0.0f});  // inside of view

    XCTAssertTrue(began_called);
    began_called = false;
    XCTAssertFalse(ended_called);

    manager.inputtable().input_cursor_event(ui::cursor_event{0.0f});  // inside of view

    XCTAssertFalse(began_called);
    XCTAssertFalse(ended_called);

    manager.inputtable().input_cursor_event(ui::cursor_event{-2.0f});  // outsize of view

    XCTAssertFalse(began_called);
    XCTAssertTrue(ended_called);
    ended_called = false;

    manager.inputtable().input_cursor_event(ui::cursor_event{-2.0f});  // outsize of view

    XCTAssertFalse(began_called);
    XCTAssertFalse(ended_called);
}

- (void)test_input_touch_events {
    ui::event_manager manager;

    bool began_called = false;
    bool ended_called = false;

    auto observer = manager.subject().make_wild_card_observer(
        [&began_called, &ended_called, self](auto const &method, ui::event const &event) {
            XCTAssertEqual(method, ui::event_method::touch_changed);

            if (event.get<ui::touch>().identifier() == 1) {
                if (event.phase() == ui::event_phase::began) {
                    began_called = true;
                } else if (event.phase() == ui::event_phase::ended) {
                    ended_called = true;
                }
            }
        });

    manager.inputtable().input_touch_event(ui::event_phase::ended, ui::touch_event{1, 0.0f});

    XCTAssertFalse(began_called);
    XCTAssertFalse(ended_called);

    manager.inputtable().input_touch_event(ui::event_phase::began, ui::touch_event{2, 0.0f});

    XCTAssertFalse(began_called);
    XCTAssertFalse(ended_called);

    manager.inputtable().input_touch_event(ui::event_phase::ended, ui::touch_event{1, 0.0f});

    XCTAssertFalse(began_called);
    XCTAssertFalse(ended_called);

    manager.inputtable().input_touch_event(ui::event_phase::began, ui::touch_event{1, 0.0f});

    XCTAssertTrue(began_called);
    began_called = false;
    XCTAssertFalse(ended_called);

    manager.inputtable().input_touch_event(ui::event_phase::began, ui::touch_event{1, 0.0f});

    XCTAssertFalse(began_called);
    XCTAssertFalse(ended_called);

    manager.inputtable().input_touch_event(ui::event_phase::ended, ui::touch_event{1, 0.0f});

    XCTAssertFalse(began_called);
    XCTAssertTrue(ended_called);
    ended_called = false;

    manager.inputtable().input_touch_event(ui::event_phase::ended, ui::touch_event{1, 0.0f});

    XCTAssertFalse(began_called);
    XCTAssertFalse(ended_called);
}

- (void)test_input_key_events {
    ui::event_manager manager;

    bool began_called = false;
    bool ended_called = false;

    auto observer = manager.subject().make_wild_card_observer(
        [&began_called, &ended_called, self](auto const &method, ui::event const &event) {
            XCTAssertEqual(method, ui::event_method::key_changed);

            if (event.get<ui::key>().key_code() == 1) {
                if (event.phase() == ui::event_phase::began) {
                    began_called = true;
                } else if (event.phase() == ui::event_phase::ended) {
                    ended_called = true;
                }
            }
        });

    manager.inputtable().input_key_event(ui::event_phase::ended, ui::key_event{1, "", ""});

    XCTAssertFalse(began_called);
    XCTAssertFalse(ended_called);

    manager.inputtable().input_key_event(ui::event_phase::began, ui::key_event{2, "", ""});

    XCTAssertFalse(began_called);
    XCTAssertFalse(ended_called);

    manager.inputtable().input_key_event(ui::event_phase::ended, ui::key_event{1, "", ""});

    XCTAssertFalse(began_called);
    XCTAssertFalse(ended_called);

    manager.inputtable().input_key_event(ui::event_phase::began, ui::key_event{1, "", ""});

    XCTAssertTrue(began_called);
    began_called = false;
    XCTAssertFalse(ended_called);

    manager.inputtable().input_key_event(ui::event_phase::began, ui::key_event{1, "", ""});

    XCTAssertFalse(began_called);
    XCTAssertFalse(ended_called);

    manager.inputtable().input_key_event(ui::event_phase::ended, ui::key_event{1, "", ""});

    XCTAssertFalse(began_called);
    XCTAssertTrue(ended_called);
    ended_called = false;

    manager.inputtable().input_key_event(ui::event_phase::ended, ui::key_event{1, "", ""});

    XCTAssertFalse(began_called);
    XCTAssertFalse(ended_called);
}

- (void)test_input_modifier_events {
    ui::event_manager manager;

    bool began_called = false;
    bool ended_called = false;

    auto observer = manager.subject().make_wild_card_observer(
        [&began_called, &ended_called, self](auto const &method, ui::event const &event) {
            XCTAssertEqual(method, ui::event_method::modifier_changed);

            if (event.get<ui::modifier>().flag() == ui::modifier_flags::alpha_shift) {
                if (event.phase() == ui::event_phase::began) {
                    began_called = true;
                } else if (event.phase() == ui::event_phase::ended) {
                    ended_called = true;
                }
            }
        });

    manager.inputtable().input_modifier_event(ui::modifier_flags(0));

    XCTAssertFalse(began_called);
    XCTAssertFalse(ended_called);

    manager.inputtable().input_modifier_event(ui::modifier_flags::command);

    XCTAssertFalse(began_called);
    XCTAssertFalse(ended_called);

    manager.inputtable().input_modifier_event(ui::modifier_flags(0));

    XCTAssertFalse(began_called);
    XCTAssertFalse(ended_called);

    manager.inputtable().input_modifier_event(ui::modifier_flags::alpha_shift);

    XCTAssertTrue(began_called);
    began_called = false;
    XCTAssertFalse(ended_called);

    manager.inputtable().input_modifier_event(ui::modifier_flags::alpha_shift);

    XCTAssertFalse(began_called);
    XCTAssertFalse(ended_called);

    manager.inputtable().input_modifier_event(ui::modifier_flags(0));

    XCTAssertFalse(began_called);
    XCTAssertTrue(ended_called);
    ended_called = false;

    manager.inputtable().input_modifier_event(ui::modifier_flags(0));

    XCTAssertFalse(began_called);
    XCTAssertFalse(ended_called);

    manager.inputtable().input_modifier_event(
        ui::modifier_flags(ui::modifier_flags::alpha_shift | ui::modifier_flags::command));

    XCTAssertTrue(began_called);
    began_called = false;
    XCTAssertFalse(ended_called);

    manager.inputtable().input_modifier_event(ui::modifier_flags::command);

    XCTAssertFalse(began_called);
    XCTAssertTrue(ended_called);
    ended_called = false;
}

@end
