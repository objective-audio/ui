//
//  yas_ui_color_tests.mm
//

#import <XCTest/XCTest.h>
#import <sstream>
#import "yas_ui_color.h"

using namespace yas;

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
    XCTAssertEqual(to_string(ui::color{1.0f, 2.0f, 3.0f}), "{1.000000, 2.000000, 3.000000}");
}

- (void)test_color_ostream {
    std::ostringstream stream;
    stream << ui::color{13.0f, 14.0f, 15.0f};
    XCTAssertEqual(stream.str(), "{13.000000, 14.000000, 15.000000}");
}

- (void)test_create_color {
    ui::color c = {.v = 1.0f};

    XCTAssertEqual(c.red, 1.0f);
    XCTAssertEqual(c.green, 1.0f);
    XCTAssertEqual(c.blue, 1.0f);
}

- (void)test_create_color_with_params {
    ui::color c{1.0f, 2.0f, 3.0f};

    XCTAssertEqual(c.red, 1.0f);
    XCTAssertEqual(c.green, 2.0f);
    XCTAssertEqual(c.blue, 3.0f);
}

- (void)test_is_equal_colors {
    ui::color c1{1.0f, 2.0f, 3.0f};
    ui::color c2{1.0f, 2.0f, 3.0f};
    ui::color c3{1.1f, 2.0f, 3.0f};
    ui::color c4{1.0f, 2.1f, 3.0f};
    ui::color c5{1.0f, 2.0f, 3.1f};
    ui::color c6{1.1f, 2.1f, 3.1f};
    ui::color cz1{0.0f, 0.0f, 0.0f};
    ui::color cz2{0.0f, 0.0f, 0.0f};

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
    ui::color c1{0.1f, 0.5f, 1.0f};
    ui::color c2{0.5f, 0.5f, 0.5f};
    
    XCTAssertTrue((c1 * c2) == (ui::color{0.05f, 0.25f, 0.5f}));
    XCTAssertTrue((c1 * 0.5f) == (ui::color{0.05f, 0.25f, 0.5f}));
}

- (void)test_static_colors {
    XCTAssertEqual(ui::white_color().red, 1.0f);
    XCTAssertEqual(ui::white_color().green, 1.0f);
    XCTAssertEqual(ui::white_color().blue, 1.0f);

    XCTAssertEqual(ui::black_color().red, 0.0f);
    XCTAssertEqual(ui::black_color().green, 0.0f);
    XCTAssertEqual(ui::black_color().blue, 0.0f);

    XCTAssertEqual(ui::gray_color().red, 0.5f);
    XCTAssertEqual(ui::gray_color().green, 0.5f);
    XCTAssertEqual(ui::gray_color().blue, 0.5f);

    XCTAssertEqual(ui::dark_gray_color().red, 0.333f);
    XCTAssertEqual(ui::dark_gray_color().green, 0.333f);
    XCTAssertEqual(ui::dark_gray_color().blue, 0.333f);

    XCTAssertEqual(ui::light_gray_color().red, 0.667f);
    XCTAssertEqual(ui::light_gray_color().green, 0.667f);
    XCTAssertEqual(ui::light_gray_color().blue, 0.667f);

    XCTAssertEqual(ui::red_color().red, 1.0f);
    XCTAssertEqual(ui::red_color().green, 0.0f);
    XCTAssertEqual(ui::red_color().blue, 0.0f);

    XCTAssertEqual(ui::green_color().red, 0.0f);
    XCTAssertEqual(ui::green_color().green, 1.0f);
    XCTAssertEqual(ui::green_color().blue, 0.0f);

    XCTAssertEqual(ui::blue_color().red, 0.0f);
    XCTAssertEqual(ui::blue_color().green, 0.0f);
    XCTAssertEqual(ui::blue_color().blue, 1.0f);

    XCTAssertEqual(ui::cyan_color().red, 0.0f);
    XCTAssertEqual(ui::cyan_color().green, 1.0f);
    XCTAssertEqual(ui::cyan_color().blue, 1.0f);

    XCTAssertEqual(ui::yellow_color().red, 1.0f);
    XCTAssertEqual(ui::yellow_color().green, 1.0f);
    XCTAssertEqual(ui::yellow_color().blue, 0.0f);

    XCTAssertEqual(ui::magenta_color().red, 1.0f);
    XCTAssertEqual(ui::magenta_color().green, 0.0f);
    XCTAssertEqual(ui::magenta_color().blue, 1.0f);

    XCTAssertEqual(ui::orange_color().red, 1.0f);
    XCTAssertEqual(ui::orange_color().green, 0.5f);
    XCTAssertEqual(ui::orange_color().blue, 0.0f);

    XCTAssertEqual(ui::purple_color().red, 0.5f);
    XCTAssertEqual(ui::purple_color().green, 0.0f);
    XCTAssertEqual(ui::purple_color().blue, 0.5f);

    XCTAssertEqual(ui::brown_color().red, 0.6f);
    XCTAssertEqual(ui::brown_color().green, 0.4f);
    XCTAssertEqual(ui::brown_color().blue, 0.2f);
}

@end
