//
//  yas_ui_hsb_color_tests.mm
//

#import <XCTest/XCTest.h>
#import <ui/yas_ui_color.h>

using namespace yas;

@interface yas_ui_hsb_color_tests : XCTestCase

@end

@implementation yas_ui_hsb_color_tests

- (void)test_hsb_white_color {
    {
        auto const color = ui::hsb_color(0.0f, 0.0f, 1.0f);
        XCTAssertEqual(color.red, 1.0f);
        XCTAssertEqual(color.green, 1.0f);
        XCTAssertEqual(color.blue, 1.0f);
    }

    {
        auto const color = ui::hsb_color(0.5f, 0.0f, 1.0f);
        XCTAssertEqual(color.red, 1.0f);
        XCTAssertEqual(color.green, 1.0f);
        XCTAssertEqual(color.blue, 1.0f);
    }

    {
        auto const color = ui::hsb_color(0.9f, 0.0f, 1.0f);
        XCTAssertEqual(color.red, 1.0f);
        XCTAssertEqual(color.green, 1.0f);
        XCTAssertEqual(color.blue, 1.0f);
    }
}

- (void)test_hsb_black_color {
    {
        auto const color = ui::hsb_color(0.0f, 0.0f, 0.0f);
        XCTAssertEqual(color.red, 0.0f);
        XCTAssertEqual(color.green, 0.0f);
        XCTAssertEqual(color.blue, 0.0f);
    }

    {
        auto const color = ui::hsb_color(0.5f, 0.0f, 0.0f);
        XCTAssertEqual(color.red, 0.0f);
        XCTAssertEqual(color.green, 0.0f);
        XCTAssertEqual(color.blue, 0.0f);
    }

    {
        auto const color = ui::hsb_color(0.9f, 0.0f, 0.0f);
        XCTAssertEqual(color.red, 0.0f);
        XCTAssertEqual(color.green, 0.0f);
        XCTAssertEqual(color.blue, 0.0f);
    }
}

- (void)test_gray_color {
    {
        auto const color = ui::hsb_color(0.0f, 0.0f, 0.5f);
        XCTAssertEqual(color.red, 0.5f);
        XCTAssertEqual(color.green, 0.5f);
        XCTAssertEqual(color.blue, 0.5f);
    }

    {
        auto const color = ui::hsb_color(0.5f, 0.0f, 0.5f);
        XCTAssertEqual(color.red, 0.5f);
        XCTAssertEqual(color.green, 0.5f);
        XCTAssertEqual(color.blue, 0.5f);
    }

    {
        auto const color = ui::hsb_color(0.9f, 0.0f, 0.5f);
        XCTAssertEqual(color.red, 0.5f);
        XCTAssertEqual(color.green, 0.5f);
        XCTAssertEqual(color.blue, 0.5f);
    }
}

- (void)test_hsb_red_color {
    {
        auto const color = ui::hsb_color(0.0f, 1.0f, 1.0f);
        XCTAssertEqual(color.red, 1.0f);
        XCTAssertEqual(color.green, 0.0f);
        XCTAssertEqual(color.blue, 0.0f);
    }

    {
        auto const color = ui::hsb_color(1.0f, 1.0f, 1.0f);
        XCTAssertEqual(color.red, 1.0f);
        XCTAssertEqual(color.green, 0.0f);
        XCTAssertEqual(color.blue, 0.0f);
    }
}

- (void)test_hsb_red_yellow_color {
    auto const color = ui::hsb_color(0.25f / 6.0f, 1.0f, 1.0f);
    XCTAssertEqual(color.red, 1.0f);
    XCTAssertEqual(color.green, 0.25f);
    XCTAssertEqual(color.blue, 0.0f);
}

- (void)test_hsb_yellow_color {
    auto const color = ui::hsb_color(1.0f / 6.0f, 1.0f, 1.0f);
    XCTAssertEqual(color.red, 1.0f);
    XCTAssertEqual(color.green, 1.0f);
    XCTAssertEqual(color.blue, 0.0f);
}

- (void)test_hsb_yellow_green_color {
    auto const color = ui::hsb_color(1.25f / 6.0f, 1.0f, 1.0f);
    XCTAssertEqual(color.red, 0.75f);
    XCTAssertEqual(color.green, 1.0f);
    XCTAssertEqual(color.blue, 0.0f);
}

- (void)test_hsb_green_color {
    auto const color = ui::hsb_color(2.0f / 6.0f, 1.0f, 1.0f);
    XCTAssertEqual(color.red, 0.0f);
    XCTAssertEqual(color.green, 1.0f);
    XCTAssertEqual(color.blue, 0.0f);
}

- (void)test_hsb_green_cyan_color {
    auto const color = ui::hsb_color(2.25f / 6.0f, 1.0f, 1.0f);
    XCTAssertEqual(color.red, 0.0f);
    XCTAssertEqual(color.green, 1.0f);
    XCTAssertEqual(color.blue, 0.25f);
}

- (void)test_hsb_cyan_color {
    auto const color = ui::hsb_color(3.0f / 6.0f, 1.0f, 1.0f);
    XCTAssertEqual(color.red, 0.0f);
    XCTAssertEqual(color.green, 1.0f);
    XCTAssertEqual(color.blue, 1.0f);
}

- (void)test_hsb_cyan_blue_color {
    auto const color = ui::hsb_color(3.25f / 6.0f, 1.0f, 1.0f);
    XCTAssertEqual(color.red, 0.0f);
    XCTAssertEqual(color.green, 0.75f);
    XCTAssertEqual(color.blue, 1.0f);
}

- (void)test_hsb_blue_color {
    auto const color = ui::hsb_color(4.0f / 6.0f, 1.0f, 1.0f);
    XCTAssertEqual(color.red, 0.0f);
    XCTAssertEqual(color.green, 0.0f);
    XCTAssertEqual(color.blue, 1.0f);
}

- (void)test_hsb_blue_magenta_color {
    auto const color = ui::hsb_color(4.25f / 6.0f, 1.0f, 1.0f);
    XCTAssertEqual(color.red, 0.25f);
    XCTAssertEqual(color.green, 0.0f);
    XCTAssertEqual(color.blue, 1.0f);
}

- (void)test_hsb_magenta_color {
    auto const color = ui::hsb_color(5.0f / 6.0f, 1.0f, 1.0f);
    XCTAssertEqual(color.red, 1.0f);
    XCTAssertEqual(color.green, 0.0f);
    XCTAssertEqual(color.blue, 1.0f);
}

- (void)test_hsb_magenta_red_color {
    auto const color = ui::hsb_color(5.25f / 6.0f, 1.0f, 1.0f);
    XCTAssertEqual(color.red, 1.0f);
    XCTAssertEqual(color.green, 0.0f);
    XCTAssertEqual(color.blue, 0.75f);
}

@end
