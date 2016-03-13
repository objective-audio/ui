//
//  yas_ui_texture_tests.mm
//

#import <XCTest/XCTest.h>
#import "yas_objc_macros.h"
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
    ui::texture texture{{2, 1}, 2.0};

    XCTAssertEqual(texture.target(), MTLTextureType2D);
    XCTAssertTrue(texture.point_size() == (ui::uint_size{2, 1}));
    XCTAssertTrue(texture.actual_size() == (ui::uint_size{4, 2}));
    XCTAssertEqual(texture.scale_factor(), 2.0);
    XCTAssertEqual(texture.depth(), 1);
    XCTAssertEqual(texture.pixel_format(), MTLPixelFormatRGBA8Unorm);
    XCTAssertEqual(texture.has_alpha(), false);
}

- (void)test_add_image {
    ui::texture texture{{8, 8}, 1.0};

    auto device = MTLCreateSystemDefaultDevice();
    if (!device) {
        std::cout << "skip : " << __PRETTY_FUNCTION__ << std::endl;
        return;
    }

    auto setup_result = texture.setup(device);
    XCTAssertTrue(setup_result);

    if (!setup_result) {
        std::cout << "setup_error::" << to_string(setup_result.error()) << std::endl;
    }

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

    yas_release(device);
}

@end
