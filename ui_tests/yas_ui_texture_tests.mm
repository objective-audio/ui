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
#import "yas_ui_texture_element.h"

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

- (void)test_add_draw_handler {
    auto device = make_objc_ptr(MTLCreateSystemDefaultDevice());
    if (!device) {
        std::cout << "skip : " << __PRETTY_FUNCTION__ << std::endl;
        return;
    }

    ui::metal_system metal_system{device.object()};

    ui::texture texture{{.point_size = {8, 8}, .scale_factor = 1.0}};
    texture.metal().metal_setup(metal_system);

    auto draw_handler = [](CGContextRef const context) {
        auto const width = CGBitmapContextGetWidth(context);
        auto const height = CGBitmapContextGetHeight(context);
        CGContextSetFillColorWithColor(context, [NSColor whiteColor].CGColor);
        CGContextFillRect(context, CGRectMake(0, 0, width, height));
    };

    auto element = texture.add_draw_handler({1, 1}, draw_handler);

    XCTAssertEqual(element.tex_coords().origin.x, 2);
    XCTAssertEqual(element.tex_coords().origin.y, 2);
    XCTAssertEqual(element.tex_coords().size.width, 1);
    XCTAssertEqual(element.tex_coords().size.height, 1);

    element = texture.add_draw_handler({1, 1}, draw_handler);

    XCTAssertEqual(element.tex_coords().origin.x, 5);
    XCTAssertEqual(element.tex_coords().origin.y, 2);
    XCTAssertEqual(element.tex_coords().size.width, 1);
    XCTAssertEqual(element.tex_coords().size.height, 1);

    element = texture.add_draw_handler({1, 1}, draw_handler);

    XCTAssertEqual(element.tex_coords().origin.x, 2);
    XCTAssertEqual(element.tex_coords().origin.y, 5);
    XCTAssertEqual(element.tex_coords().size.width, 1);
    XCTAssertEqual(element.tex_coords().size.height, 1);
}

- (void)test_remove_draw_handler {
    auto device = make_objc_ptr(MTLCreateSystemDefaultDevice());
    if (!device) {
        std::cout << "skip : " << __PRETTY_FUNCTION__ << std::endl;
        return;
    }

    ui::metal_system metal_system{device.object()};

    ui::texture texture{{.point_size = {8, 8}, .scale_factor = 1.0}};

    bool called = false;

    auto draw_handler = [&called](CGContextRef const) { called = true; };

    auto const &element = texture.add_draw_handler({1, 1}, draw_handler);

    texture.remove_draw_handler(element);

    texture.metal().metal_setup(metal_system);

    XCTAssertFalse(called);
}

- (void)test_observe_tex_coords {
    auto device = make_objc_ptr(MTLCreateSystemDefaultDevice());
    if (!device) {
        std::cout << "skip : " << __PRETTY_FUNCTION__ << std::endl;
        return;
    }

    ui::metal_system metal_system{device.object()};

    ui::texture texture{{.point_size = {8, 8}, .scale_factor = 1.0}};

    auto draw_handler = [](CGContextRef const) {};

    ui::texture_element element = texture.add_draw_handler({1, 1}, draw_handler);

    XCTAssertTrue(element.tex_coords() == ui::uint_region::zero());

    bool called = false;

    auto observer = element.subject().make_observer(ui::texture_element::method::tex_coords_changed,
                                                    [&called](auto const &context) { called = true; });

    XCTAssertFalse(called);

    texture.metal().metal_setup(metal_system);

    XCTAssertTrue(called);
    XCTAssertFalse(element.tex_coords() == ui::uint_region::zero());

    called = false;

    texture.set_scale_factor(2.0);
    texture.metal().metal_setup(metal_system);

    XCTAssertTrue(called);
    XCTAssertFalse(element.tex_coords() == ui::uint_region::zero());
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

- (void)test_method_to_string {
    XCTAssertEqual(to_string(ui::texture::method::metal_texture_changed), "metal_texture_changed");
    XCTAssertEqual(to_string(ui::texture::method::size_updated), "size_updated");
}

- (void)test_method_ostream {
    auto const methods = {ui::texture::method::metal_texture_changed, ui::texture::method::size_updated};

    for (auto const &method : methods) {
        std::ostringstream stream;
        stream << method;
        XCTAssertEqual(stream.str(), to_string(method));
    }
}

- (void)test_begin_flow {
    auto device = make_objc_ptr(MTLCreateSystemDefaultDevice());
    if (!device) {
        std::cout << "skip : " << __PRETTY_FUNCTION__ << std::endl;
        return;
    }

    ui::metal_system metal_system{device.object()};

    ui::texture texture{{.point_size = {8, 8}, .scale_factor = 1.0}};

    opt_t<ui::texture::method> received;

    auto flow = texture.begin_flow().perform([&received](auto const &pair) { received = pair.first; }).end();

    texture.set_point_size({16, 16});

    XCTAssertTrue(received);
    XCTAssertEqual(*received, ui::texture::method::size_updated);

    received = nullopt;

    texture.metal().metal_setup(metal_system);

    XCTAssertTrue(received);
    XCTAssertEqual(*received, ui::texture::method::metal_texture_changed);
}

@end
