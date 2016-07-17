//
//  yas_ui_button_tests.mm
//

#import <XCTest/XCTest.h>
#import <sstream>
#import "yas_ui_button.h"
#import "yas_ui_square.h"

using namespace yas;

@interface yas_ui_button_tests : XCTestCase

@end

@implementation yas_ui_button_tests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)test_create {
    ui::button button{{0.0f, 1.0f, 2.0f, 3.0f}};

    XCTAssertTrue(button);
    XCTAssertTrue(button.square());
}

- (void)test_create_null {
    ui::button button{nullptr};

    XCTAssertFalse(button);
}

- (void)test_state_to_index {
    XCTAssertEqual(to_index(ui::button::states_t{}), 0);
    XCTAssertEqual(to_index({ui::button::state::press}), 1);
    XCTAssertEqual(to_index({ui::button::state::toggle}), 2);
    XCTAssertEqual(to_index({ui::button::state::toggle, ui::button::state::press}), 3);
}

- (void)test_method_to_string {
    XCTAssertEqual(to_string(ui::button::method::began), "began");
    XCTAssertEqual(to_string(ui::button::method::entered), "entered");
    XCTAssertEqual(to_string(ui::button::method::leaved), "leaved");
    XCTAssertEqual(to_string(ui::button::method::ended), "ended");
    XCTAssertEqual(to_string(ui::button::method::canceled), "canceled");
}

- (void)test_state_to_string {
    XCTAssertEqual(to_string(ui::button::state::toggle), "toggle");
    XCTAssertEqual(to_string(ui::button::state::press), "press");
    XCTAssertEqual(to_string(ui::button::state::count), "count");
}

- (void)test_method_ostream {
    auto const methods = {ui::button::method::began, ui::button::method::entered, ui::button::method::leaved,
                          ui::button::method::ended, ui::button::method::canceled};

    for (auto const &method : methods) {
        std::ostringstream stream;
        stream << method;
        XCTAssertEqual(stream.str(), to_string(method));
    }
}

- (void)test_state_ostream {
    auto const states = {ui::button::state::toggle, ui::button::state::press, ui::button::state::count};

    for (auto const &state : states) {
        std::ostringstream stream;
        stream << state;
        XCTAssertEqual(stream.str(), to_string(state));
    }
}

@end
