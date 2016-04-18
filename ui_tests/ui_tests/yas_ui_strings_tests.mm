//
//  yas_ui_strings_tests.mm
//

#import <XCTest/XCTest.h>
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
    ui::font_atlas font_atlas{"HelveticaNeue", 14.0, "abcde12345", texture};

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
    ui::font_atlas font_atlas{"HelveticaNeue", 14.0, "abcde12345", texture};

    auto strings_layout = font_atlas.make_strings_layout("a1z", ui::pivot::left);

    XCTAssertEqual(strings_layout.squares().size(), 3);
    XCTAssertEqual(strings_layout.word_count(), 3);
    XCTAssertGreaterThan(strings_layout.width(), 0);

    for (auto const &sq_idx : make_each(2)) {
        auto const &prev_square = strings_layout.square(sq_idx);
        auto const &next_square = strings_layout.square(sq_idx + 1);

        for (auto const &vtx_idx : make_each(4)) {
            XCTAssertGreaterThan(next_square.v[vtx_idx].position.x, prev_square.v[vtx_idx].position.x);
            XCTAssertEqual(next_square.v[vtx_idx].position.y, prev_square.v[vtx_idx].position.y);
        }
    }
}

@end
