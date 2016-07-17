//
//  yas_ui_strings_tests.mm
//

#import <Metal/Metal.h>
#import <XCTest/XCTest.h>
#import <iostream>
#import "yas_objc_ptr.h"
#import "yas_ui_font_atlas.h"
#import "yas_ui_rect_plane.h"
#import "yas_ui_strings.h"

using namespace yas;

@interface yas_ui_strings_tests : XCTestCase

@end

@implementation yas_ui_strings_tests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)test_create {
    ui::strings strings{{.font_atlas = nullptr, .max_word_count = 16}};

    XCTAssertTrue(strings);

    XCTAssertFalse(strings.font_atlas());
    XCTAssertEqual(strings.text().size(), 0);
    XCTAssertEqual(strings.pivot(), ui::pivot::left);
    XCTAssertEqual(strings.width(), 0.0f);

    XCTAssertEqual(strings.rect_plane().data().max_rect_count(), 16);
}

- (void)test_create_with_font_atlas {
    ui::font_atlas font_atlas{{.font_name = "HelveticaNeue", .font_size = 14.0, .words = "abcde12345"}};

    ui::strings strings{{.font_atlas = font_atlas, .max_word_count = 8}};

    XCTAssertTrue(strings);

    XCTAssertTrue(strings.font_atlas());
    XCTAssertEqual(strings.font_atlas(), font_atlas);
}

- (void)test_create_null {
    ui::strings strings{nullptr};

    XCTAssertFalse(strings);
}

- (void)test_variables {
    auto device = make_objc_ptr(MTLCreateSystemDefaultDevice());
    if (!device) {
        std::cout << "skip : " << __PRETTY_FUNCTION__ << std::endl;
        return;
    }

    ui::metal_system metal_system{device.object()};

    ui::strings strings{{.font_atlas = nullptr, .max_word_count = 4}};

    auto texture =
        ui::make_texture({.metal_system = metal_system, .point_size = {256, 256}, .scale_factor = 1.0}).value();
    ui::font_atlas font_atlas{
        {.font_name = "HelveticaNeue", .font_size = 14.0, .words = "abcde12345", .texture = texture}};
    strings.set_font_atlas(font_atlas);

    XCTAssertTrue(strings.font_atlas());
    XCTAssertEqual(strings.font_atlas(), font_atlas);

    strings.set_text("test_text");

    XCTAssertEqual(strings.text(), "test_text");

    strings.set_pivot(ui::pivot::right);

    XCTAssertEqual(strings.pivot(), ui::pivot::right);
}

@end
