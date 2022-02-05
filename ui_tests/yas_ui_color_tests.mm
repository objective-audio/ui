//
//  yas_ui_color_tests.mm
//

#import <XCTest/XCTest.h>
#include <ui/yas_ui_color.h>
#include <sstream>

using namespace yas;
using namespace yas::ui;

@interface yas_ui_color_tests : XCTestCase

@end

@implementation yas_ui_color_tests

- (void)test_color_to_string {
    XCTAssertEqual(to_string(color{1.0f, 2.0f, 3.0f, 4.0f}), "{{1.000000, 2.000000, 3.000000}, 4.000000}");
}

- (void)test_color_ostream {
    std::ostringstream stream;
    stream << color{13.0f, 14.0f, 15.0f, 16.0f};
    XCTAssertEqual(stream.str(), "{{13.000000, 14.000000, 15.000000}, 16.000000}");
}

- (void)test_create_color_with_v {
    color const c{.v = 1.0f};

    XCTAssertEqual(c.red, 1.0f);
    XCTAssertEqual(c.green, 1.0f);
    XCTAssertEqual(c.blue, 1.0f);
    XCTAssertEqual(c.alpha, 1.0f);

    XCTAssertEqual(c.rgb.red, 1.0f);
    XCTAssertEqual(c.rgb.green, 1.0f);
    XCTAssertEqual(c.rgb.blue, 1.0f);
}

- (void)test_create_color_with_floats {
    color const c{.v = {1.0f, 2.0f, 3.0f, 4.0f}};

    XCTAssertEqual(c.red, 1.0f);
    XCTAssertEqual(c.green, 2.0f);
    XCTAssertEqual(c.blue, 3.0f);
    XCTAssertEqual(c.alpha, 4.0f);

    XCTAssertEqual(c.rgb.red, 1.0f);
    XCTAssertEqual(c.rgb.green, 2.0f);
    XCTAssertEqual(c.rgb.blue, 3.0f);
}

- (void)test_v {
    color const c{1.0f, 2.0f, 3.0f, 4.0f};

    XCTAssertEqual(c.v[0], 1.0f);
    XCTAssertEqual(c.v[1], 2.0f);
    XCTAssertEqual(c.v[2], 3.0f);
    XCTAssertEqual(c.v[3], 4.0f);
}

- (void)test_is_equal_colors {
    color c1{1.0f, 2.0f, 3.0f, 4.0f};
    color c2{1.0f, 2.0f, 3.0f, 4.0f};
    color c3{1.1f, 2.0f, 3.0f, 4.0f};
    color c4{1.0f, 2.1f, 3.0f, 4.0f};
    color c5{1.0f, 2.0f, 3.1f, 4.0f};
    color c6{1.0f, 2.0f, 3.0f, 4.1f};

    color c7{1.1f, 2.1f, 3.1f, 4.1f};

    color cz1{0.0f, 0.0f, 0.0f, 0.0f};
    color cz2{0.0f, 0.0f, 0.0f, 0.0f};

    XCTAssertTrue(c1 == c2);
    XCTAssertFalse(c1 == c3);
    XCTAssertFalse(c1 == c4);
    XCTAssertFalse(c1 == c5);
    XCTAssertFalse(c1 == c6);
    XCTAssertFalse(c1 == c7);
    XCTAssertTrue(cz1 == cz2);

    XCTAssertFalse(c1 != c2);
    XCTAssertTrue(c1 != c3);
    XCTAssertTrue(c1 != c4);
    XCTAssertTrue(c1 != c5);
    XCTAssertTrue(c1 != c6);
    XCTAssertTrue(c1 != c7);
    XCTAssertFalse(cz1 != cz2);
}

@end
