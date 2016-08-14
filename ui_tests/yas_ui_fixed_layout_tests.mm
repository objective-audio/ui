//
//  yas_ui_fixed_layout_tests.mm
//

#import <XCTest/XCTest.h>
#import "yas_ui_fixed_layout.h"

using namespace yas;

@interface yas_ui_fixed_layout_tests : XCTestCase

@end

@implementation yas_ui_fixed_layout_tests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)test_create {
    ui::layout_guide src_guide{0.5f};
    ui::layout_guide dst_guide{0.25f};

    ui::fixed_layout layout{{.distance = 8.0f, .source_guide = src_guide, .destination_guide = dst_guide}};

    XCTAssertTrue(layout);
    XCTAssertTrue(layout.source_guide());
    XCTAssertTrue(layout.destination_guide());
    XCTAssertEqual(layout.distance(), 8.0f);
    XCTAssertEqual(layout.source_guide().value(), 0.5f);
    XCTAssertEqual(layout.destination_guide().value(), 8.5f);
}

- (void)test_create_null {
    ui::fixed_layout layout{nullptr};
}

- (void)test_value_changed {
    ui::layout_guide src_guide{2.0f};
    ui::layout_guide dst_guide{-4.0f};

    ui::fixed_layout layout{{.distance = 1.0f, .source_guide = src_guide, .destination_guide = dst_guide}};

    XCTAssertEqual(dst_guide.value(), 3.0f);

    layout.set_distance(-4.0f);

    XCTAssertEqual(dst_guide.value(), -2.0f);

    src_guide.set_value(5.0f);

    XCTAssertEqual(dst_guide.value(), 1.0f);
}

@end
