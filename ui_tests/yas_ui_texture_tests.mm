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

- (void)test_add_image_handler {
    auto device = make_objc_ptr(MTLCreateSystemDefaultDevice());
    if (!device) {
        std::cout << "skip : " << __PRETTY_FUNCTION__ << std::endl;
        return;
    }

    ui::metal_system metal_system{device.object()};

    ui::texture texture{{.point_size = {8, 8}, .scale_factor = 1.0}};
    texture.metal().metal_setup(metal_system);

    ui::uint_region provided_tex_coords;

    auto image_handler = [&provided_tex_coords](ui::image &image, ui::uint_region const &tex_coords) {
        image.draw([](auto const context) {
            auto const width = CGBitmapContextGetWidth(context);
            auto const height = CGBitmapContextGetHeight(context);
            CGContextSetFillColorWithColor(context, [NSColor whiteColor].CGColor);
            CGContextFillRect(context, CGRectMake(0, 0, width, height));
        });

        provided_tex_coords = tex_coords;
    };

    texture.add_image_handler({1, 1}, image_handler);

    XCTAssertEqual(provided_tex_coords.origin.x, 2);
    XCTAssertEqual(provided_tex_coords.origin.y, 2);
    XCTAssertEqual(provided_tex_coords.size.width, 1);
    XCTAssertEqual(provided_tex_coords.size.height, 1);

    texture.add_image_handler({1, 1}, image_handler);

    XCTAssertEqual(provided_tex_coords.origin.x, 5);
    XCTAssertEqual(provided_tex_coords.origin.y, 2);
    XCTAssertEqual(provided_tex_coords.size.width, 1);
    XCTAssertEqual(provided_tex_coords.size.height, 1);

    texture.add_image_handler({1, 1}, image_handler);

    XCTAssertEqual(provided_tex_coords.origin.x, 2);
    XCTAssertEqual(provided_tex_coords.origin.y, 5);
    XCTAssertEqual(provided_tex_coords.size.width, 1);
    XCTAssertEqual(provided_tex_coords.size.height, 1);
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
