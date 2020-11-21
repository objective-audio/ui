//
//  yas_ui_font_atlas_tests.mm
//

#import <CoreText/CoreText.h>
#import <XCTest/XCTest.h>
#import <cpp_utils/yas_cf_ref.h>
#import <cpp_utils/yas_cf_utils.h>
#import <cpp_utils/yas_each_index.h>
#import <cpp_utils/yas_objc_ptr.h>
#import <ui/ui.h>
#import <iostream>

using namespace yas;

@interface yas_ui_font_atlas_tests : XCTestCase

@end

@implementation yas_ui_font_atlas_tests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)test_create {
    auto device = objc_ptr_with_move_object(MTLCreateSystemDefaultDevice());
    if (!device) {
        std::cout << "skip : " << __PRETTY_FUNCTION__ << std::endl;
        return;
    }

    auto metal_system = ui::metal_system::make_shared(device.object());

    auto texture = ui::texture::make_shared({.point_size = {256, 256}, .scale_factor = 1.0});
    auto font_atlas = ui::font_atlas::make_shared(
        {.font_name = "HelveticaNeue", .font_size = 14.0, .words = "abcde12345", .texture = texture});

    XCTAssertEqual(font_atlas->font_name(), "HelveticaNeue");
    XCTAssertEqual(font_atlas->font_size(), 14.0);
    XCTAssertEqual(font_atlas->words(), "abcde12345");
    XCTAssertEqual(font_atlas->texture(), texture);

    auto ct_font_ref =
        cf_ref_with_move_object(CTFontCreateWithName(to_cf_object(std::string("HelveticaNeue")), 14.0, nullptr));
    auto ct_font_obj = ct_font_ref.object();
    XCTAssertEqual(font_atlas->ascent(), CTFontGetAscent(ct_font_obj));
    XCTAssertEqual(font_atlas->descent(), CTFontGetDescent(ct_font_obj));
    XCTAssertEqual(font_atlas->leading(), CTFontGetLeading(ct_font_obj));
}

- (void)test_chain_texture {
    auto device = objc_ptr_with_move_object(MTLCreateSystemDefaultDevice());
    if (!device) {
        std::cout << "skip : " << __PRETTY_FUNCTION__ << std::endl;
        return;
    }

    auto font_atlas =
        ui::font_atlas::make_shared({.font_name = "HelveticaNeue", .font_size = 14.0, .words = "abcde12345"});

    ui::texture_ptr observed_texture = nullptr;

    auto observer = font_atlas->chain_texture()
                        .perform([&observed_texture](ui::texture_ptr const &texture) { observed_texture = texture; })
                        .end();

    auto metal_system = ui::metal_system::make_shared(device.object());

    auto texture = ui::texture::make_shared({.point_size = {256, 256}});
    font_atlas->set_texture(texture);

    XCTAssertEqual(font_atlas->texture(), texture);
    XCTAssertEqual(observed_texture, font_atlas->texture());

    font_atlas->set_texture(nullptr);

    XCTAssertFalse(font_atlas->texture());
    XCTAssertFalse(observed_texture);
}

@end
