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

#pragma mark - ui::layout_vertical_range

- (void)test_create_vertical_range {
    ui::layout_vertical_range range;

    XCTAssertTrue(range.top_guide());
    XCTAssertTrue(range.bottom_guide());
    XCTAssertEqual(range.top_guide().value(), 0.0f);
    XCTAssertEqual(range.bottom_guide().value(), 0.0f);
}

- (void)test_create_vertical_range_with_args {
    ui::layout_vertical_range range{{.top_value = 1.0, .bottom_value = 2.0f}};

    XCTAssertTrue(range.top_guide());
    XCTAssertTrue(range.bottom_guide());
    XCTAssertEqual(range.top_guide().value(), 1.0f);
    XCTAssertEqual(range.bottom_guide().value(), 2.0f);
}

- (void)test_create_vertical_range_null {
    ui::layout_vertical_range range{nullptr};

    XCTAssertFalse(range);
}

#pragma mark - ui::layout_horizontal_range

- (void)test_create_horizontal_range {
    ui::layout_horizontal_range range;

    XCTAssertTrue(range.left_guide());
    XCTAssertTrue(range.right_guide());
    XCTAssertEqual(range.left_guide().value(), 0.0f);
    XCTAssertEqual(range.right_guide().value(), 0.0f);
}

- (void)test_create_horizontal_range_with_args {
    ui::layout_horizontal_range range{{.left_value = 3.0f, .right_value = 4.0f}};

    XCTAssertTrue(range.left_guide());
    XCTAssertTrue(range.right_guide());
    XCTAssertEqual(range.left_guide().value(), 3.0f);
    XCTAssertEqual(range.right_guide().value(), 4.0f);
}

- (void)test_create_horizontal_range_null {
    ui::layout_horizontal_range range{nullptr};

    XCTAssertFalse(range);
}

#pragma mark - ui::layout_rect

- (void)test_create_rect {
    ui::layout_rect rect;

    XCTAssertTrue(rect.vertical_range().top_guide());
    XCTAssertTrue(rect.vertical_range().bottom_guide());
    XCTAssertTrue(rect.horizontal_range().left_guide());
    XCTAssertTrue(rect.horizontal_range().right_guide());
    XCTAssertEqual(rect.vertical_range().top_guide().value(), 0.0f);
    XCTAssertEqual(rect.vertical_range().bottom_guide().value(), 0.0f);
    XCTAssertEqual(rect.horizontal_range().left_guide().value(), 0.0f);
    XCTAssertEqual(rect.horizontal_range().right_guide().value(), 0.0f);
}

- (void)test_create_rect_with_args {
    ui::layout_rect rect{{.vertical_range = {.top_value = 11.0f, .bottom_value = 12.0f},
                          .horizontal_range = {.left_value = 13.0f, .right_value = 14.0f}}};

    XCTAssertTrue(rect.vertical_range().top_guide());
    XCTAssertTrue(rect.vertical_range().bottom_guide());
    XCTAssertTrue(rect.horizontal_range().left_guide());
    XCTAssertTrue(rect.horizontal_range().right_guide());
    XCTAssertEqual(rect.vertical_range().top_guide().value(), 11.0f);
    XCTAssertEqual(rect.vertical_range().bottom_guide().value(), 12.0f);
    XCTAssertEqual(rect.horizontal_range().left_guide().value(), 13.0f);
    XCTAssertEqual(rect.horizontal_range().right_guide().value(), 14.0f);
}

- (void)test_create_rect_null {
    ui::layout_rect rect{nullptr};

    XCTAssertFalse(rect);
}

@end
