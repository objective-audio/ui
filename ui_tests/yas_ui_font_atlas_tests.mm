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

    auto texture =
        ui::make_texture({.metal_system = metal_system, .point_size = {256, 256}, .scale_factor = 1.0}).value();
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

- (void)test_make_strings_layout {
    auto device = make_objc_ptr(MTLCreateSystemDefaultDevice());
    if (!device) {
        std::cout << "skip : " << __PRETTY_FUNCTION__ << std::endl;
        return;
    }

    ui::metal_system metal_system{device.object()};

    auto texture =
        ui::make_texture({.metal_system = metal_system, .point_size = {256, 256}, .scale_factor = 1.0}).value();
    ui::font_atlas font_atlas{
        {.font_name = "HelveticaNeue", .font_size = 14.0, .words = "abcde12345", .texture = texture}};

    auto strings_layout = font_atlas.make_strings_layout("a1z", ui::pivot::left);

    XCTAssertEqual(strings_layout.rects().size(), 3);
    XCTAssertEqual(strings_layout.word_count(), 3);
    XCTAssertGreaterThan(strings_layout.width(), 0);

    for (auto const &vtx_idx : make_each(4)) {
        XCTAssertGreaterThan(strings_layout.rect(1).v[vtx_idx].position.x,
                             strings_layout.rect(0).v[vtx_idx].position.x);
        XCTAssertEqual(strings_layout.rect(1).v[vtx_idx].position.y, strings_layout.rect(0).v[vtx_idx].position.y);
    }

    for (auto const &vtx_idx : make_each(4)) {
        for (auto const &pos_idx : make_each(2)) {
            XCTAssertEqual(strings_layout.rect(2).v[vtx_idx].position[pos_idx], 0);
        }
    }
}

- (void)test_observe_texture_changed {
    auto device = make_objc_ptr(MTLCreateSystemDefaultDevice());
    if (!device) {
        std::cout << "skip : " << __PRETTY_FUNCTION__ << std::endl;
        return;
    }

    ui::font_atlas font_atlas{{.font_name = "HelveticaNeue", .font_size = 14.0, .words = "abcde12345"}};

    ui::texture observed_texture = nullptr;

    auto observer = font_atlas.subject().make_observer(
        ui::font_atlas::method::texture_changed,
        [&observed_texture](auto const &context) mutable { observed_texture = context.value.texture(); });

    ui::metal_system metal_system{device.object()};

    auto texture = ui::make_texture({.metal_system = metal_system, .point_size = {256, 256}}).value();
    font_atlas.set_texture(texture);

    XCTAssertEqual(font_atlas.texture(), texture);
    XCTAssertEqual(observed_texture, font_atlas.texture());

    font_atlas.set_texture(nullptr);

    XCTAssertFalse(font_atlas.texture());
    XCTAssertFalse(observed_texture);
}

- (void)test_method_to_string {
    XCTAssertEqual(to_string(ui::font_atlas::method::texture_changed), "texture_changed");
}

@end
