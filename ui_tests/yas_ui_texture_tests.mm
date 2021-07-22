//
//  yas_ui_texture_tests.mm
//

#import <XCTest/XCTest.h>
#import <cpp_utils/yas_objc_ptr.h>
#import <objc_utils/yas_objc_macros.h>
#import <ui/ui.h>
#import <iostream>
#import <sstream>
#import "yas_ui_view_look_stubs.h"

using namespace yas;
using namespace yas::ui;

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
    auto device = objc_ptr_with_move_object(MTLCreateSystemDefaultDevice());
    if (!device) {
        std::cout << "skip : " << __PRETTY_FUNCTION__ << std::endl;
        return;
    }

    auto const metal_system = metal_system::make_shared(device.object(), nil);
    auto const view_look = view_look_scale_factor_stub::make_shared(2.0);

    auto texture = texture::make_shared({.point_size = {2, 1}}, view_look);

    XCTAssertTrue(texture->point_size() == (uint_size{2, 1}));
    XCTAssertTrue(texture->actual_size() == (uint_size{4, 2}));
    XCTAssertEqual(texture->scale_factor(), 2.0);
    XCTAssertEqual(texture->depth(), 1);
    XCTAssertEqual(texture->has_alpha(), false);

    XCTAssertFalse(texture->metal_texture());
}

- (void)test_add_draw_handler {
    auto device = objc_ptr_with_move_object(MTLCreateSystemDefaultDevice());
    if (!device) {
        std::cout << "skip : " << __PRETTY_FUNCTION__ << std::endl;
        return;
    }

    auto const metal_system = metal_system::make_shared(device.object(), nil);
    auto const view_look = view_look_scale_factor_stub::make_shared(1.0);

    auto texture = texture::make_shared({.point_size = {8, 8}}, view_look);
    metal_object::cast(texture)->metal_setup(metal_system);

    auto draw_handler = [](CGContextRef const context) {
        auto const width = CGBitmapContextGetWidth(context);
        auto const height = CGBitmapContextGetHeight(context);
        CGContextSetFillColorWithColor(context, [NSColor whiteColor].CGColor);
        CGContextFillRect(context, CGRectMake(0, 0, width, height));
    };

    auto element = texture->add_draw_handler({1, 1}, draw_handler);

    XCTAssertEqual(element->tex_coords().origin.x, 2);
    XCTAssertEqual(element->tex_coords().origin.y, 2);
    XCTAssertEqual(element->tex_coords().size.width, 1);
    XCTAssertEqual(element->tex_coords().size.height, 1);

    element = texture->add_draw_handler({1, 1}, draw_handler);

    XCTAssertEqual(element->tex_coords().origin.x, 5);
    XCTAssertEqual(element->tex_coords().origin.y, 2);
    XCTAssertEqual(element->tex_coords().size.width, 1);
    XCTAssertEqual(element->tex_coords().size.height, 1);

    element = texture->add_draw_handler({1, 1}, draw_handler);

    XCTAssertEqual(element->tex_coords().origin.x, 2);
    XCTAssertEqual(element->tex_coords().origin.y, 5);
    XCTAssertEqual(element->tex_coords().size.width, 1);
    XCTAssertEqual(element->tex_coords().size.height, 1);
}

- (void)test_remove_draw_handler {
    auto device = objc_ptr_with_move_object(MTLCreateSystemDefaultDevice());
    if (!device) {
        std::cout << "skip : " << __PRETTY_FUNCTION__ << std::endl;
        return;
    }

    auto const metal_system = metal_system::make_shared(device.object(), nil);
    auto const view_look = view_look_scale_factor_stub::make_shared(1.0);

    auto texture = texture::make_shared({.point_size = {8, 8}}, view_look);

    bool called = false;

    auto draw_handler = [&called](CGContextRef const) { called = true; };

    auto const &element = texture->add_draw_handler({1, 1}, draw_handler);

    texture->remove_draw_handler(element);

    metal_object::cast(texture)->metal_setup(metal_system);

    XCTAssertFalse(called);
}

- (void)test_observe_tex_coords {
    auto device = objc_ptr_with_move_object(MTLCreateSystemDefaultDevice());
    if (!device) {
        std::cout << "skip : " << __PRETTY_FUNCTION__ << std::endl;
        return;
    }

    auto const metal_system = metal_system::make_shared(device.object(), nil);
    auto const view_look = view_look_scale_factor_stub::make_shared(1.0);

    auto texture = texture::make_shared({.point_size = {8, 8}}, view_look);

    auto draw_handler = [](CGContextRef const) {};

    std::shared_ptr<texture_element> const &element = texture->add_draw_handler({1, 1}, draw_handler);

    XCTAssertTrue(element->tex_coords() == uint_region::zero());

    bool called = false;

    auto canceller = element->observe_tex_coords([&called](auto const &) { called = true; }).end();

    XCTAssertFalse(called);

    metal_object::cast(texture)->metal_setup(metal_system);

    XCTAssertTrue(called);
    XCTAssertFalse(element->tex_coords() == uint_region::zero());

    called = false;

#warning todo
    texture->set_scale_factor(2.0);
    metal_object::cast(texture)->metal_setup(metal_system);

    XCTAssertTrue(called);
    XCTAssertFalse(element->tex_coords() == uint_region::zero());
}

- (void)test_is_equal {
    auto device = objc_ptr_with_move_object(MTLCreateSystemDefaultDevice());
    if (!device) {
        std::cout << "skip : " << __PRETTY_FUNCTION__ << std::endl;
        return;
    }

    auto const metal_system = metal_system::make_shared(device.object(), nil);
    auto const view_look = view_look_scale_factor_stub::make_shared(1.0);

    auto texture1a = texture::make_shared(texture_args{}, view_look);
    auto texture1b = texture1a;
    auto texture2 = texture::make_shared(texture_args{}, view_look);

    XCTAssertTrue(texture1a == texture1a);
    XCTAssertTrue(texture1a == texture1b);
    XCTAssertFalse(texture1a == texture2);
}

- (void)test_is_not_equal {
    auto device = objc_ptr_with_move_object(MTLCreateSystemDefaultDevice());
    if (!device) {
        std::cout << "skip : " << __PRETTY_FUNCTION__ << std::endl;
        return;
    }

    auto const metal_system = metal_system::make_shared(device.object(), nil);
    auto const view_look = view_look_scale_factor_stub::make_shared(1.0);

    auto texture1a = texture::make_shared(texture_args{}, view_look);
    auto texture1b = texture1a;
    auto texture2 = texture::make_shared(texture_args{}, view_look);

    XCTAssertFalse(texture1a != texture1a);
    XCTAssertFalse(texture1a != texture1b);
    XCTAssertTrue(texture1a != texture2);
}

- (void)test_observe_metal_texture_updated {
    auto device = objc_ptr_with_move_object(MTLCreateSystemDefaultDevice());
    if (!device) {
        std::cout << "skip : " << __PRETTY_FUNCTION__ << std::endl;
        return;
    }

    auto const metal_system = metal_system::make_shared(device.object(), nil);
    auto const view_look = view_look_scale_factor_stub::make_shared(1.0);

    auto texture = texture::make_shared({.point_size = {8, 8}}, view_look);

    std::size_t received = 0;

    auto canceller = texture->observe_metal_texture_changed([&received](auto const &) { received += 1; });

    metal_object::cast(texture)->metal_setup(metal_system);

    XCTAssertEqual(received, 1);
}

- (void)test_observe_size_updated {
    auto const view_look = view_look_scale_factor_stub::make_shared(1.0);

    auto texture = texture::make_shared({.point_size = {8, 8}}, view_look);

    std::size_t received = 0;

    auto canceller = texture->observe_size_updated([&received](auto const &) { received += 1; });

    texture->set_point_size({16, 16});

    XCTAssertEqual(received, 1);
}

@end
