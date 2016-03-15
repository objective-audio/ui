//
//  yas_ui_strings_tests.mm
//

#import <XCTest/XCTest.h>
#import "yas_each_index.h"
#import "yas_ui_strings_data.h"
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
    ui::texture texture{{256, 256}, 1.0};

    ui::strings_data strings_data{"HelveticaNeue", 14.0, "abcde12345", texture};

    XCTAssertEqual(strings_data.font_name(), "HelveticaNeue");
    XCTAssertEqual(strings_data.font_size(), 14.0);
    XCTAssertEqual(strings_data.words(), "abcde12345");
    XCTAssertEqual(strings_data.texture(), texture);
}

- (void)test_make_strings_info {
    ui::texture texture{{256, 256}, 1.0};
    ui::strings_data strings_data{"HelveticaNeue", 14.0, "abcde12345", texture};

    auto strings_info = strings_data.make_strings_info("a1z", ui::pivot::left);

    XCTAssertEqual(strings_info.squares().size(), 3);
    XCTAssertEqual(strings_info.word_count(), 3);
    XCTAssertGreaterThan(strings_info.width(), 0);

    for (auto const &sq_idx : make_each(2)) {
        auto const &prev_square = strings_info.square(sq_idx);
        auto const &next_square = strings_info.square(sq_idx + 1);

        for (auto const &vtx_idx : make_each(4)) {
            XCTAssertGreaterThan(next_square.v[vtx_idx].position.x, prev_square.v[vtx_idx].position.x);
            XCTAssertEqual(next_square.v[vtx_idx].position.y, prev_square.v[vtx_idx].position.y);
        }
    }
}

@end
