//
//  yas_ui_color_tests.mm
//

#import <XCTest/XCTest.h>
#import <ui/ui.h>
#import <sstream>

using namespace yas;
using namespace yas::ui;

@interface yas_ui_color_tests : XCTestCase

@end

@implementation yas_ui_color_tests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)test_color_to_string {
    XCTAssertEqual(to_string(color{1.0f, 2.0f, 3.0f}), "{1.000000, 2.000000, 3.000000}");
}

- (void)test_color_ostream {
    std::ostringstream stream;
    stream << color{13.0f, 14.0f, 15.0f};
    XCTAssertEqual(stream.str(), "{13.000000, 14.000000, 15.000000}");
}

- (void)test_create_color {
    color c = {.v = 1.0f};

    XCTAssertEqual(c.red, 1.0f);
    XCTAssertEqual(c.green, 1.0f);
    XCTAssertEqual(c.blue, 1.0f);
}

- (void)test_create_color_with_params {
    color c{1.0f, 2.0f, 3.0f};

    XCTAssertEqual(c.red, 1.0f);
    XCTAssertEqual(c.green, 2.0f);
    XCTAssertEqual(c.blue, 3.0f);
}

- (void)test_is_equal_colors {
    color c1{1.0f, 2.0f, 3.0f};
    color c2{1.0f, 2.0f, 3.0f};
    color c3{1.1f, 2.0f, 3.0f};
    color c4{1.0f, 2.1f, 3.0f};
    color c5{1.0f, 2.0f, 3.1f};
    color c6{1.1f, 2.1f, 3.1f};
    color cz1{0.0f, 0.0f, 0.0f};
    color cz2{0.0f, 0.0f, 0.0f};

    XCTAssertTrue(c1 == c2);
    XCTAssertFalse(c1 == c3);
    XCTAssertFalse(c1 == c4);
    XCTAssertFalse(c1 == c5);
    XCTAssertFalse(c1 == c6);
    XCTAssertTrue(cz1 == cz2);

    XCTAssertFalse(c1 != c2);
    XCTAssertTrue(c1 != c3);
    XCTAssertTrue(c1 != c4);
    XCTAssertTrue(c1 != c5);
    XCTAssertTrue(c1 != c6);
    XCTAssertFalse(cz1 != cz2);
}

- (void)test_multiply_colors {
    color c1{0.1f, 0.5f, 1.0f};
    color c2{0.5f, 0.5f, 0.5f};

    XCTAssertTrue((c1 * c2) == (color{0.05f, 0.25f, 0.5f}));
    XCTAssertTrue((c1 * 0.5f) == (color{0.05f, 0.25f, 0.5f}));
}

- (void)test_static_colors {
    XCTAssertEqual(white_color().red, 1.0f);
    XCTAssertEqual(white_color().green, 1.0f);
    XCTAssertEqual(white_color().blue, 1.0f);

    XCTAssertEqual(black_color().red, 0.0f);
    XCTAssertEqual(black_color().green, 0.0f);
    XCTAssertEqual(black_color().blue, 0.0f);

    XCTAssertEqual(gray_color().red, 0.5f);
    XCTAssertEqual(gray_color().green, 0.5f);
    XCTAssertEqual(gray_color().blue, 0.5f);

    XCTAssertEqual(dark_gray_color().red, 0.333f);
    XCTAssertEqual(dark_gray_color().green, 0.333f);
    XCTAssertEqual(dark_gray_color().blue, 0.333f);

    XCTAssertEqual(light_gray_color().red, 0.667f);
    XCTAssertEqual(light_gray_color().green, 0.667f);
    XCTAssertEqual(light_gray_color().blue, 0.667f);

    XCTAssertEqual(red_color().red, 1.0f);
    XCTAssertEqual(red_color().green, 0.0f);
    XCTAssertEqual(red_color().blue, 0.0f);

    XCTAssertEqual(green_color().red, 0.0f);
    XCTAssertEqual(green_color().green, 1.0f);
    XCTAssertEqual(green_color().blue, 0.0f);

    XCTAssertEqual(blue_color().red, 0.0f);
    XCTAssertEqual(blue_color().green, 0.0f);
    XCTAssertEqual(blue_color().blue, 1.0f);

    XCTAssertEqual(cyan_color().red, 0.0f);
    XCTAssertEqual(cyan_color().green, 1.0f);
    XCTAssertEqual(cyan_color().blue, 1.0f);

    XCTAssertEqual(yellow_color().red, 1.0f);
    XCTAssertEqual(yellow_color().green, 1.0f);
    XCTAssertEqual(yellow_color().blue, 0.0f);

    XCTAssertEqual(magenta_color().red, 1.0f);
    XCTAssertEqual(magenta_color().green, 0.0f);
    XCTAssertEqual(magenta_color().blue, 1.0f);

    XCTAssertEqual(orange_color().red, 1.0f);
    XCTAssertEqual(orange_color().green, 0.5f);
    XCTAssertEqual(orange_color().blue, 0.0f);

    XCTAssertEqual(purple_color().red, 0.5f);
    XCTAssertEqual(purple_color().green, 0.0f);
    XCTAssertEqual(purple_color().blue, 0.5f);

    XCTAssertEqual(brown_color().red, 0.6f);
    XCTAssertEqual(brown_color().green, 0.4f);
    XCTAssertEqual(brown_color().blue, 0.2f);
}

@end
