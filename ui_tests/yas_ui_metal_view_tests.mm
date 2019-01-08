//
//  yas_ui_metal_view_tests.mm
//

#import <XCTest/XCTest.h>
#import <cpp_utils/yas_objc_ptr.h>
#import <ui/yas_ui_event.h>
#import <ui/yas_ui_metal_view.h>
#import "yas_test_metal_view_controller.h"

using namespace yas;

@interface YASUIMetalView (yas_ui_metal_view_tests)

- (yas::ui::event_manager const &)event_manager;
- (void)set_event_manager:(ui::event_manager)manager;

@end

@interface yas_ui_metal_view_tests : XCTestCase

@end

@implementation yas_ui_metal_view_tests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [[YASTestMetalViewController sharedViewController] setRenderable:nullptr];
    [super tearDown];
}

- (void)test_create {
    auto view_ptr = make_objc_ptr([[YASUIMetalView alloc] initWithFrame:CGRectMake(0.0, 0.0, 256, 256) device:nil]);
    auto view = view_ptr.object();

    XCTAssertNotNil(view);
    XCTAssertFalse([view event_manager]);
    XCTAssertTrue([view acceptsFirstResponder]);
}

- (void)test_cursor_event {
    auto view = [YASTestMetalViewController sharedViewController].metalView;

    ui::event_manager event_manager;
    [view set_event_manager:event_manager];

    bool began_called = false;
    bool changed_called = false;
    bool ended_called = false;

    auto reset_flags = [&began_called, &changed_called, &ended_called]() {
        began_called = false;
        changed_called = false;
        ended_called = false;
    };

    auto observer = event_manager.chain()
                        .perform([&self, &began_called, &changed_called, &ended_called](auto const &context) {
                            auto const &method = context.method;
                            ui::event const &event = context.event;

                            XCTAssertEqual(method, ui::event_manager::method::cursor_changed);

                            if (event.phase() == ui::event_phase::began) {
                                began_called = true;
                            } else if (event.phase() == ui::event_phase::ended) {
                                ended_called = true;
                            } else if (event.phase() == ui::event_phase::changed) {
                                changed_called = true;
                            }
                        })
                        .end();

    [view mouseEntered:[self _enterExitEventWithType:NSEventTypeMouseEntered location:NSMakePoint(1, 1)]];

    XCTAssertTrue(began_called);
    XCTAssertFalse(changed_called);
    XCTAssertFalse(ended_called);

    reset_flags();

    [view mouseMoved:[self _mouseEventWithType:NSEventTypeMouseMoved location:NSMakePoint(128, 128)]];

    XCTAssertFalse(began_called);
    XCTAssertTrue(changed_called);
    XCTAssertFalse(ended_called);

    reset_flags();

    [view mouseExited:[self _enterExitEventWithType:NSEventTypeMouseExited location:NSMakePoint(1024, 1024)]];

    XCTAssertFalse(began_called);
    XCTAssertFalse(changed_called);
    XCTAssertTrue(ended_called);

    reset_flags();
}

- (void)test_touch_event {
    auto view = [YASTestMetalViewController sharedViewController].metalView;

    ui::event_manager event_manager;
    [view set_event_manager:event_manager];

    struct observed_values {
        bool began_called = false;
        bool changed_called = false;
        bool ended_called = false;

        void reset() {
            began_called = false;
            changed_called = false;
            ended_called = false;
        }
    };

    observed_values values;

    auto observer = event_manager.chain()
                        .perform([&self, &values](auto const &context) {
                            auto const &method = context.method;
                            ui::event const &event = context.event;

                            if (method == ui::event_manager::method::cursor_changed) {
                                return;
                            }

                            XCTAssertEqual(method, ui::event_manager::method::touch_changed);

                            if (event.phase() == ui::event_phase::began) {
                                values.began_called = true;
                            } else if (event.phase() == ui::event_phase::ended) {
                                values.ended_called = true;
                            } else if (event.phase() == ui::event_phase::changed) {
                                values.changed_called = true;
                            }
                        })
                        .end();

    [view mouseDown:[self _mouseEventWithType:NSEventTypeLeftMouseDown location:NSMakePoint(100, 100)]];

    XCTAssertTrue(values.began_called);
    XCTAssertFalse(values.changed_called);
    XCTAssertFalse(values.ended_called);

    values.reset();

    [view mouseDragged:[self _mouseEventWithType:NSEventTypeLeftMouseDragged location:NSMakePoint(101, 101)]];

    XCTAssertFalse(values.began_called);
    XCTAssertTrue(values.changed_called);
    XCTAssertFalse(values.ended_called);

    values.reset();

    [view mouseUp:[self _mouseEventWithType:NSEventTypeLeftMouseUp location:NSMakePoint(102, 102)]];

    XCTAssertFalse(values.began_called);
    XCTAssertFalse(values.changed_called);
    XCTAssertTrue(values.ended_called);

    values.reset();

    [view rightMouseDown:[self _mouseEventWithType:NSEventTypeRightMouseDown location:NSMakePoint(100, 100)]];

    XCTAssertTrue(values.began_called);
    XCTAssertFalse(values.changed_called);
    XCTAssertFalse(values.ended_called);

    values.reset();

    [view rightMouseDragged:[self _mouseEventWithType:NSEventTypeRightMouseDragged location:NSMakePoint(101, 101)]];

    XCTAssertFalse(values.began_called);
    XCTAssertTrue(values.changed_called);
    XCTAssertFalse(values.ended_called);

    values.reset();

    [view rightMouseUp:[self _mouseEventWithType:NSEventTypeRightMouseUp location:NSMakePoint(102, 102)]];

    XCTAssertFalse(values.began_called);
    XCTAssertFalse(values.changed_called);
    XCTAssertTrue(values.ended_called);

    values.reset();

    [view otherMouseDown:[self _mouseEventWithType:NSEventTypeOtherMouseDown location:NSMakePoint(100, 100)]];

    XCTAssertTrue(values.began_called);
    XCTAssertFalse(values.changed_called);
    XCTAssertFalse(values.ended_called);

    values.reset();

    [view otherMouseDragged:[self _mouseEventWithType:NSEventTypeOtherMouseDragged location:NSMakePoint(101, 101)]];

    XCTAssertFalse(values.began_called);
    XCTAssertTrue(values.changed_called);
    XCTAssertFalse(values.ended_called);

    values.reset();

    [view otherMouseUp:[self _mouseEventWithType:NSEventTypeOtherMouseUp location:NSMakePoint(102, 102)]];

    XCTAssertFalse(values.began_called);
    XCTAssertFalse(values.changed_called);
    XCTAssertTrue(values.ended_called);
}

- (void)test_key_event {
    auto view = [YASTestMetalViewController sharedViewController].metalView;

    ui::event_manager event_manager;
    [view set_event_manager:event_manager];

    struct observed_values {
        bool began_called = false;
        bool changed_called = false;
        bool ended_called = false;
        unsigned short key_code = 0;
        std::string characters = "";
        std::string raw_characters = "";

        void reset() {
            began_called = false;
            changed_called = false;
            ended_called = false;
            key_code = 0;
            characters = "";
            raw_characters = "";
        }
    };

    observed_values values;

    auto observer = event_manager.chain()
                        .perform([&self, &values](auto const &context) {
                            auto const &method = context.method;
                            ui::event const &event = context.event;

                            XCTAssertEqual(method, ui::event_manager::method::key_changed);

                            if (event.phase() == ui::event_phase::began) {
                                values.began_called = true;
                            } else if (event.phase() == ui::event_phase::ended) {
                                values.ended_called = true;
                            } else if (event.phase() == ui::event_phase::changed) {
                                values.changed_called = true;
                            }

                            auto const &key_event = event.get<ui::key>();
                            values.key_code = key_event.key_code();
                            values.characters = key_event.characters();
                            values.raw_characters = key_event.raw_characters();
                        })
                        .end();

    [view keyDown:[self _keyEventWithType:NSEventTypeKeyDown
                                          keyCode:1
                                       characters:@"a"
                      charactersIgnoringModifiers:@"b"
                                        isARepeat:NO]];

    XCTAssertTrue(values.began_called);
    XCTAssertFalse(values.changed_called);
    XCTAssertFalse(values.ended_called);
    XCTAssertEqual(values.key_code, 1);
    XCTAssertEqual(values.characters, "a");
    XCTAssertEqual(values.raw_characters, "b");

    values.reset();

    [view keyDown:[self _keyEventWithType:NSEventTypeKeyDown
                                          keyCode:1
                                       characters:@"a"
                      charactersIgnoringModifiers:@"b"
                                        isARepeat:YES]];

    XCTAssertFalse(values.began_called);
    XCTAssertTrue(values.changed_called);
    XCTAssertFalse(values.ended_called);
    XCTAssertEqual(values.key_code, 1);
    XCTAssertEqual(values.characters, "a");
    XCTAssertEqual(values.raw_characters, "b");

    values.reset();

    [view keyUp:[self _keyEventWithType:NSEventTypeKeyUp
                                        keyCode:1
                                     characters:@"a"
                    charactersIgnoringModifiers:@"b"
                                      isARepeat:NO]];

    XCTAssertFalse(values.began_called);
    XCTAssertFalse(values.changed_called);
    XCTAssertTrue(values.ended_called);
    XCTAssertEqual(values.key_code, 1);
    XCTAssertEqual(values.characters, "a");
    XCTAssertEqual(values.raw_characters, "b");
}

#pragma mark -

- (NSEvent *)_mouseEventWithType:(NSEventType)type location:(NSPoint)location {
    return [NSEvent mouseEventWithType:type
                              location:location
                         modifierFlags:0
                             timestamp:0
                          windowNumber:0
                               context:nil
                           eventNumber:0
                            clickCount:1
                              pressure:0];
}

- (NSEvent *)_enterExitEventWithType:(NSEventType)type location:(NSPoint)location {
    return [NSEvent enterExitEventWithType:type
                                  location:location
                             modifierFlags:0
                                 timestamp:0
                              windowNumber:0
                                   context:nil
                               eventNumber:0
                            trackingNumber:0
                                  userData:nil];
}

- (NSEvent *)_keyEventWithType:(NSEventType)type
                        keyCode:(unsigned short)keyCode
                     characters:(NSString *)characters
    charactersIgnoringModifiers:(NSString *)charactersIgnoringModifiers
                      isARepeat:(BOOL)isARepeat {
    return [NSEvent keyEventWithType:type
                            location:NSZeroPoint
                       modifierFlags:0
                           timestamp:0
                        windowNumber:0
                             context:nil
                          characters:characters
         charactersIgnoringModifiers:charactersIgnoringModifiers
                           isARepeat:isARepeat
                             keyCode:keyCode];
}

@end
