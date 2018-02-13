//
//  yas_ui_texture_tests.mm
//

#import <XCTest/XCTest.h>
#import <iostream>
#import <sstream>
#import "yas_objc_macros.h"
#import "yas_objc_ptr.h"
#import "yas_ui_image.h"
#import "yas_ui_metal_texture.h"
#import "yas_ui_texture.h"

using namespace yas;

@interface yas_ui_texture_tests : XCTestCase

@end

@implementation yas_ui_texture_tests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)test_create_texture {
    auto device = make_objc_ptr(MTLCreateSystemDefaultDevice());
    if (!device) {
        std::cout << "skip : " << __PRETTY_FUNCTION__ << std::endl;
        return;
    }

    ui::metal_system metal_system{device.object()};

    ui::texture texture{{.point_size = {2, 1}, .scale_factor = 2.0}};

    XCTAssertTrue(texture.point_size() == (ui::uint_size{2, 1}));
    XCTAssertTrue(texture.actual_size() == (ui::uint_size{4, 2}));
    XCTAssertEqual(texture.scale_factor(), 2.0);
    XCTAssertEqual(texture.depth(), 1);
    XCTAssertEqual(texture.has_alpha(), false);

    XCTAssertFalse(texture.metal_texture());
}

- (void)test_add_image {
    auto device = make_objc_ptr(MTLCreateSystemDefaultDevice());
    if (!device) {
        std::cout << "skip : " << __PRETTY_FUNCTION__ << std::endl;
        return;
    }

    ui::metal_system metal_system{device.object()};

    ui::texture texture{{.point_size = {8, 8}, .scale_factor = 1.0}};

    ui::image image{{.point_size = {1, 1}, .scale_factor = 1.0}};

    image.draw([](auto const context) {
        auto const width = CGBitmapContextGetWidth(context);
        auto const height = CGBitmapContextGetHeight(context);
        CGContextSetFillColorWithColor(context, [NSColor whiteColor].CGColor);
        CGContextFillRect(context, CGRectMake(0, 0, width, height));
    });

    auto result = texture.add_image(image);
    XCTAssertTrue(result);

    if (result) {
        XCTAssertEqual(result.value().origin.x, 2);
        XCTAssertEqual(result.value().origin.y, 2);
        XCTAssertEqual(result.value().size.width, 1);
        XCTAssertEqual(result.value().size.height, 1);
    } else {
        std::cout << "draw_image_error::" << to_string(result.error()) << std::endl;
    }

    result = texture.add_image(image);
    XCTAssertTrue(result);

    if (result) {
        XCTAssertEqual(result.value().origin.x, 5);
        XCTAssertEqual(result.value().origin.y, 2);
        XCTAssertEqual(result.value().size.width, 1);
        XCTAssertEqual(result.value().size.height, 1);
    } else {
        std::cout << "draw_image_error::" << to_string(result.error()) << std::endl;
    }

    result = texture.add_image(image);
    XCTAssertTrue(result);

    if (result) {
        XCTAssertEqual(result.value().origin.x, 2);
        XCTAssertEqual(result.value().origin.y, 5);
        XCTAssertEqual(result.value().size.width, 1);
        XCTAssertEqual(result.value().size.height, 1);
    } else {
        std::cout << "draw_image_error::" << to_string(result.error()) << std::endl;
    }
}

- (void)test_replace_image {
    auto device = make_objc_ptr(MTLCreateSystemDefaultDevice());
    if (!device) {
        std::cout << "skip : " << __PRETTY_FUNCTION__ << std::endl;
        return;
    }

    ui::metal_system metal_system{device.object()};

    ui::make_texture texture{{.point_size = {3, 3}, .scale_factor = 1.0, .draw_padding = 1}};

    ui::image white_image{{.point_size = {1, 1}, .scale_factor = 1.0}};

    white_image.draw([](auto const context) {
        auto const width = CGBitmapContextGetWidth(context);
        auto const height = CGBitmapContextGetHeight(context);
        CGContextSetFillColorWithColor(context, [NSColor whiteColor].CGColor);
        CGContextFillRect(context, CGRectMake(0, 0, width, height));
    });

    auto white_draw_result = texture.add_image(white_image);
    XCTAssertTrue(white_draw_result);

    XCTAssertEqual(white_draw_result.value().origin.x, 1);
    XCTAssertEqual(white_draw_result.value().origin.y, 1);
    XCTAssertEqual(white_draw_result.value().size.width, 1);
    XCTAssertEqual(white_draw_result.value().size.height, 1);

    ui::image black_image{{.point_size = {1, 1}, .scale_factor = 1.0}};

    black_image.draw([](auto const context) {
        auto const width = CGBitmapContextGetWidth(context);
        auto const height = CGBitmapContextGetHeight(context);
        CGContextSetFillColorWithColor(context, [NSColor blackColor].CGColor);
        CGContextFillRect(context, CGRectMake(0, 0, width, height));
    });

    auto black_draw_result = texture.replace_image(black_image, white_draw_result.value().origin);
    XCTAssertTrue(black_draw_result);

    XCTAssertEqual(black_draw_result.value().origin.x, 1);
    XCTAssertEqual(black_draw_result.value().origin.y, 1);
    XCTAssertEqual(black_draw_result.value().size.width, 1);
    XCTAssertEqual(black_draw_result.value().size.height, 1);
}

- (void)test_is_equal {
    auto device = make_objc_ptr(MTLCreateSystemDefaultDevice());
    if (!device) {
        std::cout << "skip : " << __PRETTY_FUNCTION__ << std::endl;
        return;
    }

    ui::metal_system metal_system{device.object()};

    ui::texture texture1a{ui::texture::args{}};
    ui::texture texture1b = texture1a;
    ui::texture texture2{ui::texture::args{}};

    XCTAssertTrue(texture1a == texture1a);
    XCTAssertTrue(texture1a == texture1b);
    XCTAssertFalse(texture1a == texture2);
}

- (void)test_is_not_equal {
    auto device = make_objc_ptr(MTLCreateSystemDefaultDevice());
    if (!device) {
        std::cout << "skip : " << __PRETTY_FUNCTION__ << std::endl;
        return;
    }

    ui::metal_system metal_system{device.object()};

    ui::texture texture1a{ui::texture::args{}};
    auto texture1b = texture1a;
    ui::texture texture2{ui::texture::args{}};

    XCTAssertFalse(texture1a != texture1a);
    XCTAssertFalse(texture1a != texture1b);
    XCTAssertTrue(texture1a != texture2);
}

- (void)test_draw_image_error_to_string {
    XCTAssertEqual(to_string(ui::texture::draw_image_error::unknown), "unknown");
    XCTAssertEqual(to_string(ui::texture::draw_image_error::image_is_null), "image_is_null");
    XCTAssertEqual(to_string(ui::texture::draw_image_error::no_setup), "no_setup");
    XCTAssertEqual(to_string(ui::texture::draw_image_error::out_of_range), "out_of_range");
}

- (void)test_ostream {
    auto const errors = {ui::texture::draw_image_error::unknown, ui::texture::draw_image_error::image_is_null,
                         ui::texture::draw_image_error::no_setup, ui::texture::draw_image_error::out_of_range};

    for (auto const &error : errors) {
        std::ostringstream stream;
        stream << error;
        XCTAssertEqual(stream.str(), to_string(error));
    }
}

@end
