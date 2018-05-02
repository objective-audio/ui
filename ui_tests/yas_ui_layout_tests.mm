//
//  yas_ui_fixed_layout_tests.mm
//

#import <XCTest/XCTest.h>
#import "yas_ui_layout.h"

using namespace yas;

@interface yas_ui_layout_tests : XCTestCase

@end

@implementation yas_ui_layout_tests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)test_make_fixed_layout {
    ui::layout_guide src_guide{0.5f};
    ui::layout_guide dst_guide{0.25f};

    auto layout = ui::make_flow({.distance = 8.0f, .source_guide = src_guide, .destination_guide = dst_guide});

    XCTAssertTrue(layout);

    XCTAssertEqual(src_guide.value(), 0.5f);
    XCTAssertEqual(dst_guide.value(), 8.5f);
}

- (void)test_make_fixed_layout_with_point {
    ui::point distances{.x = 0.5f, .y = 0.25f};
    ui::layout_guide_point src_guide_point{{.x = 1.0f, .y = 2.0f}};
    ui::layout_guide_point dst_guide_point{{.x = 3.0f, .y = 4.0f}};

    auto layout = ui::make_flow(
        {.distances = distances, .source_guide_point = src_guide_point, .destination_guide_point = dst_guide_point});

    XCTAssertTrue(layout);

    XCTAssertEqual(src_guide_point.point().x, 1.0f);
    XCTAssertEqual(src_guide_point.point().y, 2.0f);
    XCTAssertEqual(dst_guide_point.point().x, 1.5f);
    XCTAssertEqual(dst_guide_point.point().y, 2.25f);
}

- (void)test_make_fixed_layout_with_rect {
    ui::insets distances{.left = 5.0f, .right = 6.0f, .bottom = 7.0f, .top = 8.0f};
    ui::layout_guide_rect src_guide_rect{{.origin = {10.0f, 12.0f}, .size = {1.0f, 1.0f}}};
    ui::layout_guide_rect dst_guide_rect{{.origin = {100.0f, 110.0f}, .size = {120.0f, 130.0f}}};

    auto layout = ui::make_flow(
        {.distances = distances, .source_guide_rect = src_guide_rect, .destination_guide_rect = dst_guide_rect});

    XCTAssertTrue(layout);

    XCTAssertEqual(src_guide_rect.left().value(), 10.0f);
    XCTAssertEqual(src_guide_rect.right().value(), 11.0f);
    XCTAssertEqual(src_guide_rect.bottom().value(), 12.0f);
    XCTAssertEqual(src_guide_rect.top().value(), 13.0f);
    XCTAssertEqual(dst_guide_rect.left().value(), 15.0f);
    XCTAssertEqual(dst_guide_rect.right().value(), 17.0f);
    XCTAssertEqual(dst_guide_rect.bottom().value(), 19.0f);
    XCTAssertEqual(dst_guide_rect.top().value(), 21.0f);
}

- (void)test_fixed_layout_value_changed {
    ui::layout_guide src_guide{2.0f};
    ui::layout_guide dst_guide{-4.0f};

    auto layout = ui::make_flow({.distance = 1.0f, .source_guide = src_guide, .destination_guide = dst_guide});

    XCTAssertEqual(dst_guide.value(), 3.0f);

    src_guide.set_value(5.0f);

    XCTAssertEqual(dst_guide.value(), 6.0f);
}

#pragma mark -

- (void)test_min_layout {
    ui::layout_guide src_guide_0{1.0f};
    ui::layout_guide src_guide_1{2.0f};
    ui::layout_guide dst_guide{-1.0f};

    auto layout = ui::make_flow(
        ui::min_layout::args{.source_guides = {src_guide_0, src_guide_1}, .destination_guide = dst_guide});

    XCTAssertEqual(dst_guide.value(), 1.0f);

    src_guide_0.set_value(-1.0f);

    XCTAssertEqual(dst_guide.value(), -1.0f);

    src_guide_0.set_value(5.0f);

    XCTAssertEqual(dst_guide.value(), 2.0f);

    src_guide_1.set_value(1.0f);

    XCTAssertEqual(dst_guide.value(), 1.0f);
}

- (void)test_max_layout {
    ui::layout_guide src_guide_0{1.0f};
    ui::layout_guide src_guide_1{2.0f};
    ui::layout_guide dst_guide{3.0f};

    auto layout = ui::make_flow(
        ui::max_layout::args{.source_guides = {src_guide_0, src_guide_1}, .destination_guide = dst_guide});

    XCTAssertEqual(dst_guide.value(), 2.0f);

    src_guide_0.set_value(5.0f);

    XCTAssertEqual(dst_guide.value(), 5.0f);

    src_guide_0.set_value(-1.0f);

    XCTAssertEqual(dst_guide.value(), 2.0f);

    src_guide_1.set_value(4.0f);

    XCTAssertEqual(dst_guide.value(), 4.0f);
}

@end
