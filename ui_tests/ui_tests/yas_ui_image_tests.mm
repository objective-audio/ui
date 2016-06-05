//
//  yas_ui_image_tests.mm
//

#import <AppKit/AppKit.h>
#import <XCTest/XCTest.h>
#import "yas_each_index.h"
#import "yas_ui_image.h"
#import "yas_ui_types.h"

using namespace yas;

@interface yas_ui_image_tests : XCTestCase

@end

@implementation yas_ui_image_tests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)test_create_without_scale_factor {
    ui::image image{{.width = 4, .height = 2}};

    XCTAssertEqual(image.point_size().width, 4);
    XCTAssertEqual(image.point_size().height, 2);
    XCTAssertEqual(image.actual_size().width, 4);
    XCTAssertEqual(image.actual_size().height, 2);
    XCTAssertEqual(image.scale_factor(), 1.0);
    XCTAssertTrue(image.data() != nullptr);
}

- (void)test_create_with_scale_factor {
    ui::image image{{.width = 6, .height = 3}, 2.0};

    XCTAssertEqual(image.point_size().width, 6);
    XCTAssertEqual(image.point_size().height, 3);
    XCTAssertEqual(image.actual_size().width, 12);
    XCTAssertEqual(image.actual_size().height, 6);
    XCTAssertEqual(image.scale_factor(), 2.0);
    XCTAssertTrue(image.data() != nullptr);
}

- (void)test_draw {
    ui::image image{{.width = 2, .height = 2}};

    image.draw([](auto const context) {
        CGContextSetFillColorWithColor(context, [NSColor whiteColor].CGColor);
        CGContextFillRect(context, CGRectMake(0, 0, 2, 2));
    });

    uint8_t *data = static_cast<uint8_t *>(image.data());
    for (auto &idx : each_index<std::size_t>{2 * 2 * 4}) {
        XCTAssertEqual(data[idx], 0xFF);
    }
}

- (void)test_clear {
    ui::image image{{.width = 2, .height = 2}};

    image.draw([](auto const context) {
        CGContextSetFillColorWithColor(context, [NSColor whiteColor].CGColor);
        CGContextFillRect(context, CGRectMake(0, 0, 2, 2));
    });

    image.clear();

    uint8_t *data = static_cast<uint8_t *>(image.data());
    for (auto &idx : each_index<std::size_t>{2 * 2 * 4}) {
        XCTAssertEqual(data[idx], 0x00);
    }
}

@end
