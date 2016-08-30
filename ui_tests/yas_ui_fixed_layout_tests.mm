//
//  yas_ui_fixed_layout_tests.mm
//

#import <XCTest/XCTest.h>
#import "yas_ui_layout.h"

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

- (void)test_make_fixed_layout {
    ui::layout_guide src_guide{0.5f};
    ui::layout_guide dst_guide{0.25f};

    auto layout = ui::make_fixed_layout({.distance = 8.0f, .source_guide = src_guide, .destination_guide = dst_guide});

    XCTAssertTrue(layout);
    XCTAssertEqual(layout.source_guides().size(), 1);
    XCTAssertEqual(layout.destination_guides().size(), 1);
    XCTAssertEqual(layout.source_guides().at(0).value(), 0.5f);
    XCTAssertEqual(layout.destination_guides().at(0).value(), 8.5f);
}

- (void)test_fixed_layout_value_changed {
    ui::layout_guide src_guide{2.0f};
    ui::layout_guide dst_guide{-4.0f};

    auto layout = ui::make_fixed_layout({.distance = 1.0f, .source_guide = src_guide, .destination_guide = dst_guide});

    XCTAssertEqual(dst_guide.value(), 3.0f);

    src_guide.set_value(5.0f);

    XCTAssertEqual(dst_guide.value(), 6.0f);
}

@end
