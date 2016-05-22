//
//  yas_ui_strings_tests.mm
//

#import <XCTest/XCTest.h>
#import <iostream>
#import "yas_each_index.h"
#import "yas_objc_ptr.h"
#import "yas_ui_font_atlas.h"
#import "yas_ui_renderer.h"
#import "yas_ui_texture.h"

using namespace yas;

@interface yas_ui_strings_tests : XCTestCase

@end

@implementation yas_ui_strings_tests

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

    auto texture = ui::make_texture(device.object(), {256, 256}, 1.0).value();
    ui::font_atlas font_atlas{
        {.font_name = "HelveticaNeue", .font_size = 14.0, .words = "abcde12345", .texture = texture}};

    XCTAssertEqual(font_atlas.font_name(), "HelveticaNeue");
    XCTAssertEqual(font_atlas.font_size(), 14.0);
    XCTAssertEqual(font_atlas.words(), "abcde12345");
    XCTAssertEqual(font_atlas.texture(), texture);
}

- (void)test_make_strings_layout {
    auto device = make_objc_ptr(MTLCreateSystemDefaultDevice());
    if (!device) {
        std::cout << "skip : " << __PRETTY_FUNCTION__ << std::endl;
        return;
    }

    auto texture = ui::make_texture(device.object(), {256, 256}, 1.0).value();
    ui::font_atlas font_atlas{
        {.font_name = "HelveticaNeue", .font_size = 14.0, .words = "abcde12345", .texture = texture}};

    auto strings_layout = font_atlas.make_strings_layout("a1z", ui::pivot::left);

    XCTAssertEqual(strings_layout.squares().size(), 3);
    XCTAssertEqual(strings_layout.word_count(), 3);
    XCTAssertGreaterThan(strings_layout.width(), 0);

    for (auto const &vtx_idx : make_each(4)) {
        XCTAssertGreaterThan(strings_layout.square(1).v[vtx_idx].position.x,
                             strings_layout.square(0).v[vtx_idx].position.x);
        XCTAssertEqual(strings_layout.square(1).v[vtx_idx].position.y, strings_layout.square(0).v[vtx_idx].position.y);
    }

    for (auto const &vtx_idx : make_each(4)) {
        for (auto const &pos_idx : make_each(2)) {
            XCTAssertEqual(strings_layout.square(2).v[vtx_idx].position[pos_idx], 0);
        }
    }
}

@end
