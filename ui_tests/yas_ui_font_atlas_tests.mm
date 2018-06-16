//
//  yas_ui_font_atlas_tests.mm
//

#import <CoreText/CoreText.h>
#import <XCTest/XCTest.h>
#import <iostream>
#import "yas_cf_ref.h"
#import "yas_cf_utils.h"
#import "yas_each_index.h"
#import "yas_objc_ptr.h"
#import "yas_observing.h"
#import "yas_ui_font_atlas.h"

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
    auto device = make_objc_ptr(MTLCreateSystemDefaultDevice());
    if (!device) {
        std::cout << "skip : " << __PRETTY_FUNCTION__ << std::endl;
        return;
    }

    ui::metal_system metal_system{device.object()};

    ui::texture texture{{.point_size = {256, 256}, .scale_factor = 1.0}};
    ui::font_atlas font_atlas{
        {.font_name = "HelveticaNeue", .font_size = 14.0, .words = "abcde12345", .texture = texture}};

    XCTAssertEqual(font_atlas.font_name(), "HelveticaNeue");
    XCTAssertEqual(font_atlas.font_size(), 14.0);
    XCTAssertEqual(font_atlas.words(), "abcde12345");
    XCTAssertEqual(font_atlas.texture(), texture);

    auto ct_font_ref = make_cf_ref(CTFontCreateWithName(to_cf_object(std::string("HelveticaNeue")), 14.0, nullptr));
    auto ct_font_obj = ct_font_ref.object();
    XCTAssertEqual(font_atlas.ascent(), CTFontGetAscent(ct_font_obj));
    XCTAssertEqual(font_atlas.descent(), CTFontGetDescent(ct_font_obj));
    XCTAssertEqual(font_atlas.leading(), CTFontGetLeading(ct_font_obj));
}

- (void)test_create_null {
    ui::font_atlas atlas = nullptr;

    XCTAssertFalse(atlas);
}

- (void)test_texture_flow {
    auto device = make_objc_ptr(MTLCreateSystemDefaultDevice());
    if (!device) {
        std::cout << "skip : " << __PRETTY_FUNCTION__ << std::endl;
        return;
    }

    ui::font_atlas font_atlas{{.font_name = "HelveticaNeue", .font_size = 14.0, .words = "abcde12345"}};

    ui::texture observed_texture = nullptr;

    auto flow = font_atlas.begin_texture_flow()
                    .perform([&observed_texture](ui::texture const &texture) { observed_texture = texture; })
                    .end();

    ui::metal_system metal_system{device.object()};

    ui::texture texture{{.point_size = {256, 256}}};
    font_atlas.set_texture(texture);

    XCTAssertEqual(font_atlas.texture(), texture);
    XCTAssertEqual(observed_texture, font_atlas.texture());

    font_atlas.set_texture(nullptr);

    XCTAssertFalse(font_atlas.texture());
    XCTAssertFalse(observed_texture);
}

@end
