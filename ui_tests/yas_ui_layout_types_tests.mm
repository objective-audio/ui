//
//  yas_ui_layout_types_tests.mm
//

#import <XCTest/XCTest.h>
#import <ui/yas_ui_layout_types.h>
#import <sstream>

using namespace yas;

@interface yas_ui_layout_types_tests : XCTestCase

@end

@implementation yas_ui_layout_types_tests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)test_layout_direction_to_string {
    XCTAssertEqual(to_string(ui::layout_direction::horizontal), "horizontal");
    XCTAssertEqual(to_string(ui::layout_direction::vertical), "vertical");
}

- (void)test_layout_order_to_string {
    XCTAssertEqual(to_string(ui::layout_order::ascending), "ascending");
    XCTAssertEqual(to_string(ui::layout_order::descending), "descending");
}

- (void)test_layout_alignment_to_string {
    XCTAssertEqual(to_string(ui::layout_alignment::min), "min");
    XCTAssertEqual(to_string(ui::layout_alignment::mid), "mid");
    XCTAssertEqual(to_string(ui::layout_alignment::max), "max");
}

- (void)test_layout_borders_to_string {
    ui::layout_borders borders{.left = 1.0f, .right = 2.0f, .bottom = 3.0f, .top = 4.0f};
    XCTAssertEqual(to_string(borders), "{left=1.000000, right=2.000000, bottom=3.000000, top=4.000000}");
}

- (void)test_layout_direction_ostream {
    std::ostringstream stream;
    stream << ui::layout_direction::horizontal;
    XCTAssertEqual(stream.str(), "horizontal");
}

- (void)test_layout_order_ostream {
    std::ostringstream stream;
    stream << ui::layout_order::descending;
    XCTAssertEqual(stream.str(), "descending");
}

- (void)test_layout_alignment_ostream {
    std::ostringstream stream;
    stream << ui::layout_alignment::mid;
    XCTAssertEqual(stream.str(), "mid");
}

- (void)test_layout_borders_ostream {
    std::ostringstream stream;
    stream << ui::layout_borders{.left = 1.0f, .right = 2.0f, .bottom = 3.0f, .top = 4.0f};
    XCTAssertEqual(stream.str(), "{left=1.000000, right=2.000000, bottom=3.000000, top=4.000000}");
}

@end
