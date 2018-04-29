//
//  yas_ui_layout_tests.mm
//

#import <XCTest/XCTest.h>
#import "yas_ui_layout_guide.h"

#import <iostream>

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

    float new_value = -1.0f;
    ui::layout_guide notified_guide = nullptr;

    auto observer = guide.subject().make_observer(ui::layout_guide::method::value_changed,
                                                  [&new_value, &notified_guide](auto const &context) {
                                                      new_value = context.value.new_value;
                                                      notified_guide = context.value.layout_guide;
                                                  });

    guide.set_value(10.0f);

    XCTAssertEqual(new_value, 10.0f);
    XCTAssertTrue(notified_guide);
    XCTAssertEqual(guide, notified_guide);
}

- (void)test_value_changed_handler {
    ui::layout_guide guide;

    float handled_new_value = -1.0f;
    ui::layout_guide handled_layout_guide{nullptr};

    guide.set_value_changed_handler([&handled_new_value, &handled_layout_guide](auto const &context) {
        handled_new_value = context.new_value;
        handled_layout_guide = context.layout_guide;
    });

    guide.set_value(1.0f);

    XCTAssertEqual(handled_new_value, 1.0f);
    XCTAssertEqual(handled_layout_guide, guide);
}

- (void)test_notify_caller {
    ui::layout_guide guide;

    float handled_value = 0.0f;
    float notified_new_value = 0.0f;

    auto clear_values = [&handled_value, &notified_new_value]() { handled_value = notified_new_value = 0.0f; };

    guide.set_value_changed_handler([&handled_value](auto const &context) { handled_value = context.new_value; });

    auto observer =
        guide.begin_flow().perform([&notified_new_value](float const &value) { notified_new_value = value; }).end();

    guide.set_value(1.0f);

    XCTAssertEqual(handled_value, 1.0f);
    XCTAssertEqual(notified_new_value, 1.0f);

    clear_values();

    guide.push_notify_caller();
    guide.set_value(2.0f);

    XCTAssertEqual(handled_value, 0.0f);
    XCTAssertEqual(notified_new_value, 0.0f);

    guide.push_notify_caller();
    guide.set_value(3.0f);

    XCTAssertEqual(handled_value, 0.0f);
    XCTAssertEqual(notified_new_value, 0.0f);

    guide.pop_notify_caller();
    guide.set_value(4.0f);

    XCTAssertEqual(handled_value, 0.0f);
    XCTAssertEqual(notified_new_value, 0.0f);

    guide.pop_notify_caller();

    XCTAssertEqual(handled_value, 4.0f);
    XCTAssertEqual(notified_new_value, 4.0f);

    clear_values();

    guide.set_value(5.0f);

    XCTAssertEqual(handled_value, 5.0f);
    XCTAssertEqual(notified_new_value, 5.0f);
}

- (void)test_notify_caller_canceled {
    ui::layout_guide guide{1.0f};

    bool called = false;

    guide.set_value_changed_handler([&called](auto const &) { called = true; });

    guide.push_notify_caller();

    guide.set_value(2.0f);
    guide.set_value(1.0f);

    guide.pop_notify_caller();

    XCTAssertFalse(called);
}

#pragma mark - ui::layout_guide_point

- (void)test_create_point {
    ui::layout_guide_point point;

    XCTAssertTrue(point);
    XCTAssertTrue(point.x());
    XCTAssertTrue(point.y());
    XCTAssertEqual(point.x().value(), 0.0f);
    XCTAssertEqual(point.y().value(), 0.0f);
}

- (void)test_create_point_with_args {
    ui::layout_guide_point point{{1.0f, 2.0f}};

    XCTAssertTrue(point);
    XCTAssertTrue(point.x());
    XCTAssertTrue(point.y());
    XCTAssertEqual(point.x().value(), 1.0f);
    XCTAssertEqual(point.y().value(), 2.0f);
}

- (void)test_create_point_null {
    ui::layout_guide_point point{nullptr};

    XCTAssertFalse(point);
}

- (void)test_point_accessor {
    ui::layout_guide_point point;

    XCTAssertTrue(point.point() == (ui::point{0.0f, 0.0f}));

    point.set_point({1.0f, -1.0f});

    XCTAssertTrue(point.point() == (ui::point{1.0f, -1.0f}));
}

- (void)test_point_value_changed_handler {
    ui::layout_guide_point guide_point;

    ui::point handled_new_value{-1.0f, -1.0f};
    ui::layout_guide_point handled_guide_point{nullptr};

    guide_point.set_value_changed_handler([&handled_new_value, &handled_guide_point](auto const &context) {
        handled_new_value = context.new_value;
        handled_guide_point = context.layout_guide_point;
    });

    guide_point.set_point({1.0f, 2.0f});

    XCTAssertTrue(handled_new_value == (ui::point{1.0f, 2.0f}));
    XCTAssertTrue(handled_guide_point == guide_point);
}

- (void)test_point_notify_caller {
    ui::layout_guide_point point;

    ui::point handled_point;
    ui::point notified_new_point;

    auto is_all_zero = [](ui::point const &origin) { return origin.x == 0 && origin.y == 0; };

    auto clear_points = [&handled_point, &notified_new_point]() {
        handled_point.x = handled_point.y = 0.0f;
        notified_new_point.x = notified_new_point.y = 0.0f;
    };

    point.x().set_value_changed_handler([&handled_x = handled_point.x](auto const &context) {
        handled_x = context.new_value;
    });
    point.y().set_value_changed_handler([&handled_y = handled_point.y](auto const &context) {
        handled_y = context.new_value;
    });

    auto x_observer = point.x().subject().make_observer(
        ui::layout_guide::method::value_changed,
        [&notified_new_x = notified_new_point.x](auto const &context) { notified_new_x = context.value.new_value; });

    auto y_observer = point.y().subject().make_observer(
        ui::layout_guide::method::value_changed,
        [&notified_new_y = notified_new_point.y](auto const &context) { notified_new_y = context.value.new_value; });

    point.set_point({1.0f, 2.0f});

    XCTAssertEqual(handled_point.x, 1.0f);
    XCTAssertEqual(handled_point.y, 2.0f);
    XCTAssertEqual(notified_new_point.x, 1.0f);
    XCTAssertEqual(notified_new_point.y, 2.0f);

    clear_points();

    point.push_notify_caller();

    point.set_point({3.0f, 4.0f});

    XCTAssertTrue(is_all_zero(handled_point));
    XCTAssertTrue(is_all_zero(notified_new_point));

    point.push_notify_caller();

    point.set_point({5.0f, 6.0f});

    XCTAssertTrue(is_all_zero(handled_point));
    XCTAssertTrue(is_all_zero(notified_new_point));

    point.pop_notify_caller();

    point.set_point({7.0f, 8.0f});

    XCTAssertTrue(is_all_zero(handled_point));
    XCTAssertTrue(is_all_zero(notified_new_point));

    point.pop_notify_caller();

    XCTAssertEqual(handled_point.x, 7.0f);
    XCTAssertEqual(handled_point.y, 8.0f);
    XCTAssertEqual(notified_new_point.x, 7.0f);
    XCTAssertEqual(notified_new_point.y, 8.0f);

    clear_points();

    point.set_point({9.0f, 10.0f});

    XCTAssertEqual(handled_point.x, 9.0f);
    XCTAssertEqual(handled_point.y, 10.0f);
    XCTAssertEqual(notified_new_point.x, 9.0f);
    XCTAssertEqual(notified_new_point.y, 10.0f);
}

#pragma mark - ui::layout_guide_range

- (void)test_create_range {
    ui::layout_guide_range range;

    XCTAssertTrue(range);
    XCTAssertTrue(range.min());
    XCTAssertTrue(range.max());
    XCTAssertEqual(range.min().value(), 0.0f);
    XCTAssertEqual(range.max().value(), 0.0f);
    XCTAssertEqual(range.length().value(), 0.0f);
}

- (void)test_create_range_with_args {
    ui::layout_guide_range range{{.location = 1.0f, .length = 2.0f}};

    XCTAssertTrue(range);
    XCTAssertTrue(range.min());
    XCTAssertTrue(range.max());
    XCTAssertEqual(range.min().value(), 1.0f);
    XCTAssertEqual(range.max().value(), 3.0f);
    XCTAssertEqual(range.length().value(), 2.0f);

    range = ui::layout_guide_range{{.location = 4.0f, .length = -6.0f}};

    XCTAssertEqual(range.min().value(), -2.0f);
    XCTAssertEqual(range.max().value(), 4.0f);
    XCTAssertEqual(range.length().value(), -6.0f);
}

- (void)test_create_range_null {
    ui::layout_guide_range range{nullptr};

    XCTAssertFalse(range);
}

- (void)test_range_accessor {
    ui::layout_guide_range range;

    XCTAssertTrue(range.range() == (ui::range{.location = 0.0f, .length = 0.0f}));

    range.set_range({.location = 1.0f, .length = 2.0f});

    XCTAssertTrue(range.range() == (ui::range{1.0f, 2.0f}));
}

- (void)test_range_value_changed_handler {
    ui::layout_guide_range guide_range;

    ui::range handled_new_value{-1.0f, -1.0f};
    ui::layout_guide_range handled_guide_range{nullptr};

    guide_range.set_value_changed_handler([&handled_new_value, &handled_guide_range](auto const &context) {
        handled_new_value = context.new_value;
        handled_guide_range = context.layout_guide_range;
    });

    guide_range.set_range({1.0f, 2.0f});

    XCTAssertTrue(handled_new_value == (ui::range{1.0f, 2.0f}));
    XCTAssertEqual(handled_guide_range, guide_range);
}

- (void)test_range_notify_caller {
    ui::layout_guide_range range;

    struct edge {
        float min = 0.0f;
        float max = 0.0f;
        float length = 0.0f;

        void clear() {
            min = max = length = 0.0f;
        }

        bool is_all_zero() {
            return min == 0.0f && max == 0.0f && length == 0.0f;
        }
    };

    edge handled_edge;
    edge notified_new_edge;

    auto clear_edges = [&handled_edge, &notified_new_edge]() {
        handled_edge.clear();
        notified_new_edge.clear();
    };

    range.min().set_value_changed_handler([&handled_min = handled_edge.min](auto const &context) {
        handled_min = context.new_value;
    });
    range.max().set_value_changed_handler([&handled_max = handled_edge.max](auto const &context) {
        handled_max = context.new_value;
    });
    range.length().set_value_changed_handler([&handled_length = handled_edge.length](auto const &context) {
        handled_length = context.new_value;
    });

    auto min_observer = range.min().subject().make_observer(
        ui::layout_guide::method::value_changed, [&notified_new_min = notified_new_edge.min](auto const &context) {
            notified_new_min = context.value.new_value;
        });

    auto max_observer = range.max().subject().make_observer(
        ui::layout_guide::method::value_changed, [&notified_new_max = notified_new_edge.max](auto const &context) {
            notified_new_max = context.value.new_value;
        });

    auto length_observer =
        range.length().subject().make_observer(ui::layout_guide::method::value_changed,
                                               [&notified_new_length = notified_new_edge.length](auto const &context) {
                                                   notified_new_length = context.value.new_value;
                                               });

    range.set_range({1.0f, 2.0f});

    XCTAssertEqual(handled_edge.min, 1.0f);
    XCTAssertEqual(handled_edge.max, 3.0f);
    XCTAssertEqual(handled_edge.length, 2.0f);
    XCTAssertEqual(notified_new_edge.min, 1.0f);
    XCTAssertEqual(notified_new_edge.max, 3.0f);
    XCTAssertEqual(notified_new_edge.length, 2.0f);

    clear_edges();

    range.push_notify_caller();

    range.set_range({3.0f, 4.0f});

    XCTAssertTrue(handled_edge.is_all_zero());
    XCTAssertTrue(notified_new_edge.is_all_zero());

    range.push_notify_caller();

    range.set_range({5.0f, 6.0f});

    XCTAssertTrue(handled_edge.is_all_zero());
    XCTAssertTrue(notified_new_edge.is_all_zero());

    range.pop_notify_caller();

    range.set_range({7.0f, 8.0f});

    XCTAssertTrue(handled_edge.is_all_zero());
    XCTAssertTrue(notified_new_edge.is_all_zero());

    range.pop_notify_caller();

    XCTAssertEqual(handled_edge.min, 7.0f);
    XCTAssertEqual(handled_edge.max, 15.0f);
    XCTAssertEqual(handled_edge.length, 8.0f);
    XCTAssertEqual(notified_new_edge.min, 7.0f);
    XCTAssertEqual(notified_new_edge.max, 15.0f);
    XCTAssertEqual(notified_new_edge.length, 8.0f);

    clear_edges();

    range.set_range({9.0f, 10.0f});

    XCTAssertEqual(handled_edge.min, 9.0f);
    XCTAssertEqual(handled_edge.max, 19.0f);
    XCTAssertEqual(handled_edge.length, 10.0f);
    XCTAssertEqual(notified_new_edge.min, 9.0f);
    XCTAssertEqual(notified_new_edge.max, 19.0f);
    XCTAssertEqual(notified_new_edge.length, 10.0f);
}

- (void)test_range_set_by_guide {
    ui::layout_guide_range range;

    range.max().set_value(1.0f);

    XCTAssertEqual(range.min().value(), 0.0f);
    XCTAssertEqual(range.max().value(), 1.0f);
    XCTAssertEqual(range.length().value(), 1.0f);

    range.min().set_value(-1.0f);

    XCTAssertEqual(range.min().value(), -1.0f);
    XCTAssertEqual(range.max().value(), 1.0f);
    XCTAssertEqual(range.length().value(), 2.0f);

    range.length().set_value(3.0f);

    XCTAssertEqual(range.min().value(), -1.0f);
    XCTAssertEqual(range.max().value(), 2.0f);
    XCTAssertEqual(range.length().value(), 3.0f);
}

#pragma mark - ui::layout_guide_rect

- (void)test_create_rect {
    ui::layout_guide_rect rect;

    XCTAssertTrue(rect);
    XCTAssertTrue(rect.vertical_range());
    XCTAssertTrue(rect.horizontal_range());
    XCTAssertTrue(rect.left());
    XCTAssertTrue(rect.right());
    XCTAssertTrue(rect.bottom());
    XCTAssertTrue(rect.top());

    XCTAssertEqual(rect.vertical_range().min().value(), 0.0f);
    XCTAssertEqual(rect.vertical_range().max().value(), 0.0f);
    XCTAssertEqual(rect.horizontal_range().min().value(), 0.0f);
    XCTAssertEqual(rect.horizontal_range().max().value(), 0.0f);
    XCTAssertEqual(rect.left().value(), 0.0f);
    XCTAssertEqual(rect.right().value(), 0.0f);
    XCTAssertEqual(rect.bottom().value(), 0.0f);
    XCTAssertEqual(rect.top().value(), 0.0f);
    XCTAssertEqual(rect.width().value(), 0.0f);
    XCTAssertEqual(rect.height().value(), 0.0f);
}

- (void)test_create_rect_with_args {
    ui::layout_guide_rect rect{{.vertical_range = {.location = 11.0f, .length = 1.0f},
                                .horizontal_range = {.location = 13.0f, .length = 2.0f}}};

    XCTAssertTrue(rect);
    XCTAssertTrue(rect.vertical_range());
    XCTAssertTrue(rect.horizontal_range());
    XCTAssertTrue(rect.left());
    XCTAssertTrue(rect.right());
    XCTAssertTrue(rect.bottom());
    XCTAssertTrue(rect.top());

    XCTAssertEqual(rect.vertical_range().min().value(), 11.0f);
    XCTAssertEqual(rect.vertical_range().max().value(), 12.0f);
    XCTAssertEqual(rect.horizontal_range().min().value(), 13.0f);
    XCTAssertEqual(rect.horizontal_range().max().value(), 15.0f);
    XCTAssertEqual(rect.bottom().value(), 11.0f);
    XCTAssertEqual(rect.top().value(), 12.0f);
    XCTAssertEqual(rect.left().value(), 13.0f);
    XCTAssertEqual(rect.right().value(), 15.0f);
    XCTAssertEqual(rect.width().value(), 2.0f);
    XCTAssertEqual(rect.height().value(), 1.0f);
}

- (void)test_create_rect_null {
    ui::layout_guide_rect rect{nullptr};

    XCTAssertFalse(rect);
}

- (void)test_rect_set_vertical_ranges {
    ui::layout_guide_rect rect;

    rect.set_vertical_range({.location = 100.0f, .length = 101.0f});

    XCTAssertEqual(rect.bottom().value(), 100.0f);
    XCTAssertEqual(rect.top().value(), 201.0f);
    XCTAssertEqual(rect.left().value(), 0.0f);
    XCTAssertEqual(rect.right().value(), 0.0f);
    XCTAssertEqual(rect.width().value(), 0.0f);
    XCTAssertEqual(rect.height().value(), 101.0f);
}

- (void)test_rect_set_horizontal_ranges {
    ui::layout_guide_rect rect;

    rect.set_horizontal_range({.location = 300.0f, .length = 102.0f});

    XCTAssertEqual(rect.bottom().value(), 0.0f);
    XCTAssertEqual(rect.top().value(), 0.0f);
    XCTAssertEqual(rect.left().value(), 300.0f);
    XCTAssertEqual(rect.right().value(), 402.0f);
    XCTAssertEqual(rect.width().value(), 102.0f);
    XCTAssertEqual(rect.height().value(), 0.0f);
}

- (void)test_rect_set_ranges {
    ui::layout_guide_rect rect;

    rect.set_ranges({.vertical_range = {.location = 11.0f, .length = 1.0f},
                     .horizontal_range = {.location = 13.0f, .length = 2.0f}});

    XCTAssertEqual(rect.bottom().value(), 11.0f);
    XCTAssertEqual(rect.top().value(), 12.0f);
    XCTAssertEqual(rect.left().value(), 13.0f);
    XCTAssertEqual(rect.right().value(), 15.0f);
    XCTAssertEqual(rect.width().value(), 2.0f);
    XCTAssertEqual(rect.height().value(), 1.0f);
}

- (void)test_rect_set_region {
    ui::layout_guide_rect rect;

    rect.set_region({.origin = {1.0f, 2.0f}, .size = {3.0f, 4.0f}});

    XCTAssertEqual(rect.bottom().value(), 2.0f);
    XCTAssertEqual(rect.top().value(), 6.0f);
    XCTAssertEqual(rect.left().value(), 1.0f);
    XCTAssertEqual(rect.right().value(), 4.0f);
    XCTAssertEqual(rect.width().value(), 3.0f);
    XCTAssertEqual(rect.height().value(), 4.0f);
}

- (void)test_rect_value_changed_handler {
    ui::layout_guide_rect guide_rect;

    ui::region handled_new_value{.origin = {-1.0f, -1.0f}, .size = {-1.0f, -1.0f}};
    ui::layout_guide_rect handled_guide_rect{nullptr};

    guide_rect.set_value_changed_handler([&handled_new_value, &handled_guide_rect](auto const &context) {
        handled_new_value = context.new_value;
        handled_guide_rect = context.layout_guide_rect;
    });

    guide_rect.set_region({.origin = {1.0f, 2.0f}, .size = {3.0f, 4.0f}});

    XCTAssertTrue(handled_new_value == (ui::region{.origin = {1.0f, 2.0f}, .size = {3.0f, 4.0f}}));
    XCTAssertEqual(handled_guide_rect, guide_rect);
}

- (void)test_rect_notify_caller {
    ui::layout_guide_rect rect;

    struct edge {
        float left = 0.0f;
        float right = 0.0f;
        float bottom = 0.0f;
        float top = 0.0f;
        float width = 0.0f;
        float height = 0.0f;

        void clear() {
            left = right = bottom = top = width = height = 0.0f;
        }

        bool is_all_zero() {
            return (left == 0.0f && right == 0.0f && bottom == 0.0f && top == 0.0f && width == 0.0f && height == 0.0f);
        }
    };

    edge handled_edge;
    edge notified_old_edge;
    edge notified_new_edge;

    auto clear_edges = [&handled_edge, &notified_old_edge, &notified_new_edge]() {
        handled_edge.clear();
        notified_old_edge.clear();
        notified_new_edge.clear();
    };

    rect.left().set_value_changed_handler([&handled_left = handled_edge.left](auto const &context) {
        handled_left = context.new_value;
    });

    rect.right().set_value_changed_handler([&handled_right = handled_edge.right](auto const &context) {
        handled_right = context.new_value;
    });

    rect.bottom().set_value_changed_handler([&handled_bottom = handled_edge.bottom](auto const &context) {
        handled_bottom = context.new_value;
    });

    rect.top().set_value_changed_handler([&handled_top = handled_edge.top](auto const &context) {
        handled_top = context.new_value;
    });

    rect.width().set_value_changed_handler([&handled_width = handled_edge.width](auto const &context) {
        handled_width = context.new_value;
    });

    rect.height().set_value_changed_handler([&handled_height = handled_edge.height](auto const &context) {
        handled_height = context.new_value;
    });

    auto left_observer = rect.left().subject().make_observer(
        ui::layout_guide::method::value_changed, [&notified_new_left = notified_new_edge.left](auto const &context) {
            notified_new_left = context.value.new_value;
        });

    auto right_observer = rect.right().subject().make_observer(
        ui::layout_guide::method::value_changed, [&notified_new_right = notified_new_edge.right](auto const &context) {
            notified_new_right = context.value.new_value;
        });

    auto bottom_observer =
        rect.bottom().subject().make_observer(ui::layout_guide::method::value_changed,
                                              [&notified_new_bottom = notified_new_edge.bottom](auto const &context) {
                                                  notified_new_bottom = context.value.new_value;
                                              });

    auto top_observer = rect.top().subject().make_observer(
        ui::layout_guide::method::value_changed, [&notified_new_top = notified_new_edge.top](auto const &context) {
            notified_new_top = context.value.new_value;
        });

    auto width_observer = rect.width().subject().make_observer(
        ui::layout_guide::method::value_changed, [&notified_new_width = notified_new_edge.width](auto const &context) {
            notified_new_width = context.value.new_value;
        });

    auto height_observer =
        rect.height().subject().make_observer(ui::layout_guide::method::value_changed,
                                              [&notified_new_height = notified_new_edge.height](auto const &context) {
                                                  notified_new_height = context.value.new_value;
                                              });

    rect.set_region({.origin = {1.0f, 2.0f}, .size = {3.0f, 4.0f}});

    XCTAssertEqual(handled_edge.left, 1.0f);
    XCTAssertEqual(handled_edge.right, 4.0f);
    XCTAssertEqual(handled_edge.bottom, 2.0f);
    XCTAssertEqual(handled_edge.top, 6.0f);
    XCTAssertEqual(handled_edge.width, 3.0f);
    XCTAssertEqual(handled_edge.height, 4.0f);
    XCTAssertEqual(notified_new_edge.left, 1.0f);
    XCTAssertEqual(notified_new_edge.right, 4.0f);
    XCTAssertEqual(notified_new_edge.bottom, 2.0f);
    XCTAssertEqual(notified_new_edge.top, 6.0f);
    XCTAssertEqual(notified_new_edge.width, 3.0f);
    XCTAssertEqual(notified_new_edge.height, 4.0f);

    clear_edges();

    rect.push_notify_caller();

    rect.set_region({.origin = {5.0f, 6.0f}, .size = {7.0f, 8.0f}});

    XCTAssertTrue(handled_edge.is_all_zero());
    XCTAssertTrue(notified_new_edge.is_all_zero());

    rect.push_notify_caller();

    rect.set_region({.origin = {9.0f, 10.0f}, .size = {11.0f, 12.0f}});

    XCTAssertTrue(handled_edge.is_all_zero());
    XCTAssertTrue(notified_new_edge.is_all_zero());

    rect.pop_notify_caller();

    rect.set_region({.origin = {13.0f, 14.0f}, .size = {15.0f, 16.0f}});

    XCTAssertTrue(handled_edge.is_all_zero());
    XCTAssertTrue(notified_new_edge.is_all_zero());

    rect.pop_notify_caller();

    XCTAssertEqual(handled_edge.left, 13.0f);
    XCTAssertEqual(handled_edge.right, 28.0f);
    XCTAssertEqual(handled_edge.bottom, 14.0f);
    XCTAssertEqual(handled_edge.top, 30.0f);
    XCTAssertEqual(handled_edge.width, 15.0f);
    XCTAssertEqual(handled_edge.height, 16.0f);

    XCTAssertEqual(notified_new_edge.left, 13.0f);
    XCTAssertEqual(notified_new_edge.right, 28.0f);
    XCTAssertEqual(notified_new_edge.bottom, 14.0f);
    XCTAssertEqual(notified_new_edge.top, 30.0f);
    XCTAssertEqual(notified_new_edge.width, 15.0f);
    XCTAssertEqual(notified_new_edge.height, 16.0f);

    clear_edges();

    rect.set_region({.origin = {17.0f, 18.0f}, .size = {19.0f, 20.0f}});

    XCTAssertEqual(handled_edge.left, 17.0f);
    XCTAssertEqual(handled_edge.right, 36.0f);
    XCTAssertEqual(handled_edge.bottom, 18.0f);
    XCTAssertEqual(handled_edge.top, 38.0f);
    XCTAssertEqual(handled_edge.width, 19.0f);
    XCTAssertEqual(handled_edge.height, 20.0f);

    XCTAssertEqual(notified_new_edge.left, 17.0f);
    XCTAssertEqual(notified_new_edge.right, 36.0f);
    XCTAssertEqual(notified_new_edge.bottom, 18.0f);
    XCTAssertEqual(notified_new_edge.top, 38.0f);
    XCTAssertEqual(notified_new_edge.width, 19.0f);
    XCTAssertEqual(notified_new_edge.height, 20.0f);
}

- (void)test_rect_set_by_guide {
    ui::layout_guide_rect rect;

    // horizontal

    rect.right().set_value(1.0f);

    XCTAssertEqual(rect.left().value(), 0.0f);
    XCTAssertEqual(rect.right().value(), 1.0f);
    XCTAssertEqual(rect.width().value(), 1.0f);

    rect.left().set_value(-1.0f);

    XCTAssertEqual(rect.left().value(), -1.0f);
    XCTAssertEqual(rect.right().value(), 1.0f);
    XCTAssertEqual(rect.width().value(), 2.0f);

    rect.width().set_value(3.0f);

    XCTAssertEqual(rect.left().value(), -1.0f);
    XCTAssertEqual(rect.right().value(), 2.0f);
    XCTAssertEqual(rect.width().value(), 3.0f);

    // vertical

    rect.top().set_value(1.0f);

    XCTAssertEqual(rect.bottom().value(), 0.0f);
    XCTAssertEqual(rect.top().value(), 1.0f);
    XCTAssertEqual(rect.height().value(), 1.0f);

    rect.bottom().set_value(-1.0f);

    XCTAssertEqual(rect.bottom().value(), -1.0f);
    XCTAssertEqual(rect.top().value(), 1.0f);
    XCTAssertEqual(rect.height().value(), 2.0f);

    rect.height().set_value(3.0f);

    XCTAssertEqual(rect.bottom().value(), -1.0f);
    XCTAssertEqual(rect.top().value(), 2.0f);
    XCTAssertEqual(rect.height().value(), 3.0f);
}

@end
