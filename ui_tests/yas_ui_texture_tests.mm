//
//  yas_ui_texture_tests.mm
//

#import <XCTest/XCTest.h>
#import <cpp_utils/yas_objc_ptr.h>
#import <objc_utils/yas_objc_macros.h>
#import <ui/ui.h>
#import <iostream>
#import <sstream>

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
    auto device = objc_ptr_with_move_object(MTLCreateSystemDefaultDevice());
    if (!device) {
        std::cout << "skip : " << __PRETTY_FUNCTION__ << std::endl;
        return;
    }

    auto metal_system = ui::metal_system::make_shared(device.object());

    auto texture = ui::texture::make_shared({.point_size = {2, 1}, .scale_factor = 2.0});

    XCTAssertTrue(texture->point_size() == (ui::uint_size{2, 1}));
    XCTAssertTrue(texture->actual_size() == (ui::uint_size{4, 2}));
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

    auto metal_system = ui::metal_system::make_shared(device.object());

    auto texture = ui::texture::make_shared({.point_size = {8, 8}, .scale_factor = 1.0});
    ui::metal_object::cast(texture)->metal_setup(metal_system);

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

    auto metal_system = ui::metal_system::make_shared(device.object());

    auto texture = ui::texture::make_shared({.point_size = {8, 8}, .scale_factor = 1.0});

    bool called = false;

    auto draw_handler = [&called](CGContextRef const) { called = true; };

    auto const &element = texture->add_draw_handler({1, 1}, draw_handler);

    texture->remove_draw_handler(element);

    ui::metal_object::cast(texture)->metal_setup(metal_system);

    XCTAssertFalse(called);
}

- (void)test_observe_tex_coords {
    auto device = objc_ptr_with_move_object(MTLCreateSystemDefaultDevice());
    if (!device) {
        std::cout << "skip : " << __PRETTY_FUNCTION__ << std::endl;
        return;
    }

    auto metal_system = ui::metal_system::make_shared(device.object());

    auto texture = ui::texture::make_shared({.point_size = {8, 8}, .scale_factor = 1.0});

    auto draw_handler = [](CGContextRef const) {};

    ui::texture_element_ptr const &element = texture->add_draw_handler({1, 1}, draw_handler);

    XCTAssertTrue(element->tex_coords() == ui::uint_region::zero());

    bool called = false;

    auto observer = element->chain_tex_coords().perform([&called](auto const &) { called = true; }).end();

    XCTAssertFalse(called);

    ui::metal_object::cast(texture)->metal_setup(metal_system);

    XCTAssertTrue(called);
    XCTAssertFalse(element->tex_coords() == ui::uint_region::zero());

    called = false;

    texture->set_scale_factor(2.0);
    ui::metal_object::cast(texture)->metal_setup(metal_system);

    XCTAssertTrue(called);
    XCTAssertFalse(element->tex_coords() == ui::uint_region::zero());
}

- (void)test_is_equal {
    auto device = objc_ptr_with_move_object(MTLCreateSystemDefaultDevice());
    if (!device) {
        std::cout << "skip : " << __PRETTY_FUNCTION__ << std::endl;
        return;
    }

    auto metal_system = ui::metal_system::make_shared(device.object());

    auto texture1a = ui::texture::make_shared(ui::texture::args{});
    auto texture1b = texture1a;
    auto texture2 = ui::texture::make_shared(ui::texture::args{});

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

    auto metal_system = ui::metal_system::make_shared(device.object());

    auto texture1a = ui::texture::make_shared(ui::texture::args{});
    auto texture1b = texture1a;
    auto texture2 = ui::texture::make_shared(ui::texture::args{});

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

- (void)test_chain {
    auto device = objc_ptr_with_move_object(MTLCreateSystemDefaultDevice());
    if (!device) {
        std::cout << "skip : " << __PRETTY_FUNCTION__ << std::endl;
        return;
    }

    auto metal_system = ui::metal_system::make_shared(device.object());

    auto texture = ui::texture::make_shared({.point_size = {8, 8}, .scale_factor = 1.0});

    std::optional<ui::texture::method> received;

    auto observer = texture->chain().perform([&received](auto const &pair) { received = pair.first; }).end();

    texture->set_point_size({16, 16});

    XCTAssertTrue(received);
    XCTAssertEqual(*received, ui::texture::method::size_updated);

    received = std::nullopt;

    ui::metal_object::cast(texture)->metal_setup(metal_system);

    XCTAssertTrue(received);
    XCTAssertEqual(*received, ui::texture::method::metal_texture_changed);
}

- (void)test_chain_with_method {
    auto device = objc_ptr_with_move_object(MTLCreateSystemDefaultDevice());
    if (!device) {
        std::cout << "skip : " << __PRETTY_FUNCTION__ << std::endl;
        return;
    }

    auto metal_system = ui::metal_system::make_shared(device.object());

    auto texture = ui::texture::make_shared({.point_size = {8, 8}, .scale_factor = 1.0});

    bool called = false;

    auto observer =
        texture->chain(ui::texture::method::size_updated).perform([&called](auto const &) { called = true; }).end();

    texture->set_point_size({16, 16});

    XCTAssertTrue(called);

    called = false;

    ui::metal_object::cast(texture)->metal_setup(metal_system);

    XCTAssertFalse(called);
}

@end
