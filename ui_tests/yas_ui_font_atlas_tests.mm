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
#import "yas_ui_view_look_stubs.h"

using namespace yas;
using namespace yas::ui;

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

    auto const metal_system = metal_system::make_shared(device.object(), nil);
    auto const view_look = view_look_scale_factor_stub::make_shared(1.0);

    auto texture = texture::make_shared({.point_size = {256, 256}}, view_look);
    auto font_atlas =
        font_atlas::make_shared({.font_name = "HelveticaNeue", .font_size = 14.0, .words = "abcde12345"}, texture);

    XCTAssertEqual(font_atlas->font_name(), "HelveticaNeue");
    XCTAssertEqual(font_atlas->font_size(), 14.0);
    XCTAssertEqual(font_atlas->words(), "12345abcde", @"内部的にmapを使っているので文字コード順になる");
    XCTAssertEqual(font_atlas->texture(), texture);

    auto ct_font_ref =
        cf_ref_with_move_object(CTFontCreateWithName(to_cf_object(std::string("HelveticaNeue")), 14.0, nullptr));
    auto ct_font_obj = ct_font_ref.object();
    XCTAssertEqual(font_atlas->ascent(), CTFontGetAscent(ct_font_obj));
    XCTAssertEqual(font_atlas->descent(), CTFontGetDescent(ct_font_obj));
    XCTAssertEqual(font_atlas->leading(), CTFontGetLeading(ct_font_obj));
}

@end
