//
//  yas_ui_texture_tests.mm
//

#import <XCTest/XCTest.h>
#import "yas_objc_macros.h"
#import "yas_objc_ptr.h"
#import "yas_ui_image.h"
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

- (void)test_create {
    auto device = make_objc_ptr(MTLCreateSystemDefaultDevice());
    if (!device) {
        std::cout << "skip : " << __PRETTY_FUNCTION__ << std::endl;
        return;
    }

    auto texture = ui::make_texture(device.object(), {2, 1}, 2.0).value();

    XCTAssertEqual(texture.target(), MTLTextureType2D);
    XCTAssertTrue(texture.point_size() == (ui::uint_size{2, 1}));
    XCTAssertTrue(texture.actual_size() == (ui::uint_size{4, 2}));
    XCTAssertEqual(texture.scale_factor(), 2.0);
    XCTAssertEqual(texture.depth(), 1);
    XCTAssertEqual(texture.pixel_format(), MTLPixelFormatRGBA8Unorm);
    XCTAssertEqual(texture.has_alpha(), false);
}

- (void)test_add_image {
    auto device = make_objc_ptr(MTLCreateSystemDefaultDevice());
    if (!device) {
        std::cout << "skip : " << __PRETTY_FUNCTION__ << std::endl;
        return;
    }

    auto texture = ui::make_texture(device.object(), {8, 8}, 1.0).value();

    ui::image image{{1, 1}, 1.0};

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

- (void)test_draw_image_error_to_string {
    XCTAssertEqual(to_string(ui::texture::draw_image_error::unknown), "unknown");
    XCTAssertEqual(to_string(ui::texture::draw_image_error::image_is_null), "image_is_null");
    XCTAssertEqual(to_string(ui::texture::draw_image_error::no_setup), "no_setup");
    XCTAssertEqual(to_string(ui::texture::draw_image_error::out_of_range), "out_of_range");
}

- (void)test_ostream {
    std::cout << ui::texture::draw_image_error::unknown << std::endl;
}

@end
