//
//  yas_ui_layout_tests.mm
//

#import <XCTest/XCTest.h>
#import "yas_ui_layout_guide.h"

using namespace yas;

@interface yas_ui_layout_guide_tests : XCTestCase

@end

@implementation yas_ui_layout_guide_tests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

#pragma mark - ui::layout_guide

- (void)test_create_guide {
    ui::layout_guide guide;

    XCTAssertTrue(guide);
    XCTAssertEqual(guide.value(), 0.0f);
}

- (void)test_create_guide_with_value {
    ui::layout_guide guide{1.0f};

    XCTAssertTrue(guide);
    XCTAssertEqual(guide.value(), 1.0f);
}

- (void)test_create_guide_null {
    ui::layout_guide guide{nullptr};

    XCTAssertFalse(guide);
}

- (void)test_guide_observing {
    ui::layout_guide guide;

    float old_value = -1.0f;
    float new_value = -1.0f;
    ui::layout_guide notified_guide = nullptr;

    auto observer = guide.subject().make_observer(ui::layout_guide::method::value_changed,
                                                  [&old_value, &new_value, &notified_guide](auto const &context) {
                                                      old_value = context.value.old_value;
                                                      new_value = context.value.new_value;
                                                      notified_guide = context.value.layout_guide;
                                                  });

    guide.set_value(10.0f);

    XCTAssertEqual(old_value, 0.0f);
    XCTAssertEqual(new_value, 10.0f);
    XCTAssertTrue(notified_guide);
    XCTAssertEqual(guide, notified_guide);
}

- (void)test_value_changed_handler {
    ui::layout_guide guide;

    float handled_value = 0.0f;

    guide.set_value_changed_handler([&handled_value](auto const value) { handled_value = value; });

    guide.set_value(1.0f);

    XCTAssertEqual(handled_value, 1.0f);
}

#pragma mark - ui::layout_guide_point

- (void)test_create_point {
    ui::layout_guide_point point;

    XCTAssertTrue(point);
    XCTAssertTrue(point.x_guide());
    XCTAssertTrue(point.y_guide());
    XCTAssertEqual(point.x_guide().value(), 0.0f);
    XCTAssertEqual(point.y_guide().value(), 0.0f);
}

- (void)test_create_point_with_args {
    ui::layout_guide_point point{{.x = 1.0f, .y = 2.0f}};

    XCTAssertTrue(point);
    XCTAssertTrue(point.x_guide());
    XCTAssertTrue(point.y_guide());
    XCTAssertEqual(point.x_guide().value(), 1.0f);
    XCTAssertEqual(point.y_guide().value(), 2.0f);
}

- (void)test_create_point_null {
    ui::layout_guide_point point{nullptr};

    XCTAssertFalse(point);
}

#pragma mark - ui::layout_guide_range

- (void)test_create_range {
    ui::layout_guide_range range;

    XCTAssertTrue(range);
    XCTAssertTrue(range.min_guide());
    XCTAssertTrue(range.max_guide());
    XCTAssertEqual(range.min_guide().value(), 0.0f);
    XCTAssertEqual(range.max_guide().value(), 0.0f);
}

- (void)test_create_range_with_args {
    ui::layout_guide_range range{{.location = 1.0f, .length = 2.0f}};

    XCTAssertTrue(range);
    XCTAssertTrue(range.min_guide());
    XCTAssertTrue(range.max_guide());
    XCTAssertEqual(range.min_guide().value(), 1.0f);
    XCTAssertEqual(range.max_guide().value(), 3.0f);

    range = ui::layout_guide_range{{.location = 4.0f, .length = -6.0f}};

    XCTAssertEqual(range.min_guide().value(), -2.0f);
    XCTAssertEqual(range.max_guide().value(), 4.0f);
}

- (void)test_create_range_null {
    ui::layout_guide_range range{nullptr};

    XCTAssertFalse(range);
}

#pragma mark - ui::layout_guide_rect

- (void)test_create_rect {
    ui::layout_guide_rect rect;

    XCTAssertTrue(rect);
    XCTAssertTrue(rect.vertical_range());
    XCTAssertTrue(rect.horizontal_range());
    XCTAssertTrue(rect.left_guide());
    XCTAssertTrue(rect.right_guide());
    XCTAssertTrue(rect.bottom_guide());
    XCTAssertTrue(rect.top_guide());

    XCTAssertEqual(rect.vertical_range().min_guide().value(), 0.0f);
    XCTAssertEqual(rect.vertical_range().max_guide().value(), 0.0f);
    XCTAssertEqual(rect.horizontal_range().min_guide().value(), 0.0f);
    XCTAssertEqual(rect.horizontal_range().max_guide().value(), 0.0f);
    XCTAssertEqual(rect.left_guide().value(), 0.0f);
    XCTAssertEqual(rect.right_guide().value(), 0.0f);
    XCTAssertEqual(rect.bottom_guide().value(), 0.0f);
    XCTAssertEqual(rect.top_guide().value(), 0.0f);
}

- (void)test_create_rect_with_args {
    ui::layout_guide_rect rect{{.vertical_range = {.location = 11.0f, .length = 1.0f},
                                .horizontal_range = {.location = 13.0f, .length = 1.0f}}};

    XCTAssertTrue(rect);
    XCTAssertTrue(rect.vertical_range());
    XCTAssertTrue(rect.horizontal_range());
    XCTAssertTrue(rect.left_guide());
    XCTAssertTrue(rect.right_guide());
    XCTAssertTrue(rect.bottom_guide());
    XCTAssertTrue(rect.top_guide());

    XCTAssertEqual(rect.vertical_range().min_guide().value(), 11.0f);
    XCTAssertEqual(rect.vertical_range().max_guide().value(), 12.0f);
    XCTAssertEqual(rect.horizontal_range().min_guide().value(), 13.0f);
    XCTAssertEqual(rect.horizontal_range().max_guide().value(), 14.0f);
    XCTAssertEqual(rect.bottom_guide().value(), 11.0f);
    XCTAssertEqual(rect.top_guide().value(), 12.0f);
    XCTAssertEqual(rect.left_guide().value(), 13.0f);
    XCTAssertEqual(rect.right_guide().value(), 14.0f);
}

- (void)test_create_rect_null {
    ui::layout_guide_rect rect{nullptr};

    XCTAssertFalse(rect);
}

- (void)test_rect_set_ranges {
    ui::layout_guide_rect rect;

    rect.set_ranges({.vertical_range = {.location = 11.0f, .length = 1.0f},
                     .horizontal_range = {.location = 13.0f, .length = 1.0f}});

    XCTAssertEqual(rect.bottom_guide().value(), 11.0f);
    XCTAssertEqual(rect.top_guide().value(), 12.0f);
    XCTAssertEqual(rect.left_guide().value(), 13.0f);
    XCTAssertEqual(rect.right_guide().value(), 14.0f);
}

- (void)test_rect_set_region {
    ui::layout_guide_rect rect;

    rect.set_region({.origin = {1.0f, 2.0f}, .size = {3.0f, 4.0f}});

    XCTAssertEqual(rect.bottom_guide().value(), 2.0f);
    XCTAssertEqual(rect.top_guide().value(), 6.0f);
    XCTAssertEqual(rect.left_guide().value(), 1.0f);
    XCTAssertEqual(rect.right_guide().value(), 4.0f);
}

@end
