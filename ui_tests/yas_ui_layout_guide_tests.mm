//
//  yas_ui_layout_tests.mm
//

#import <XCTest/XCTest.h>
#import <ui/ui.h>

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
    auto guide = ui::layout_guide::make_shared();

    XCTAssertTrue(guide);
    XCTAssertEqual(guide->value(), 0.0f);
}

- (void)test_create_guide_with_value {
    auto guide = ui::layout_guide::make_shared(1.0f);

    XCTAssertTrue(guide);
    XCTAssertEqual(guide->value(), 1.0f);
}

- (void)test_notify_caller {
    auto guide = ui::layout_guide::make_shared();

    float notified_new_value = 0.0f;

    auto clear_values = [&notified_new_value]() { notified_new_value = 0.0f; };

    auto observer =
        guide->chain().perform([&notified_new_value](float const &value) { notified_new_value = value; }).end();

    guide->set_value(1.0f);

    XCTAssertEqual(notified_new_value, 1.0f);

    clear_values();

    guide->push_notify_waiting();
    guide->set_value(2.0f);

    XCTAssertEqual(notified_new_value, 0.0f);

    guide->push_notify_waiting();
    guide->set_value(3.0f);

    XCTAssertEqual(notified_new_value, 0.0f);

    guide->pop_notify_waiting();
    guide->set_value(4.0f);

    XCTAssertEqual(notified_new_value, 0.0f);

    guide->pop_notify_waiting();

    XCTAssertEqual(notified_new_value, 4.0f);

    clear_values();

    guide->set_value(5.0f);

    XCTAssertEqual(notified_new_value, 5.0f);
}

- (void)test_notify_caller_canceled {
    auto guide = ui::layout_guide::make_shared(1.0f);

    bool called = false;

    auto observer = guide->chain().perform([&called](auto const &) { called = true; }).end();

    guide->push_notify_waiting();

    guide->set_value(2.0f);
    guide->set_value(1.0f);

    guide->pop_notify_waiting();

    XCTAssertFalse(called);
}

#pragma mark - ui::layout_guide_point

- (void)test_create_point {
    auto point = ui::layout_guide_point::make_shared();

    XCTAssertTrue(point);
    XCTAssertTrue(point->x());
    XCTAssertTrue(point->y());
    XCTAssertEqual(point->x()->value(), 0.0f);
    XCTAssertEqual(point->y()->value(), 0.0f);
}

- (void)test_create_point_with_args {
    auto point = ui::layout_guide_point::make_shared({1.0f, 2.0f});

    XCTAssertTrue(point);
    XCTAssertTrue(point->x());
    XCTAssertTrue(point->y());
    XCTAssertEqual(point->x()->value(), 1.0f);
    XCTAssertEqual(point->y()->value(), 2.0f);
}

- (void)test_point_accessor {
    auto point = ui::layout_guide_point::make_shared();

    XCTAssertTrue(point->point() == (ui::point{0.0f, 0.0f}));

    point->set_point({1.0f, -1.0f});

    XCTAssertTrue(point->point() == (ui::point{1.0f, -1.0f}));
}

- (void)test_chain_point {
    auto guide_point = ui::layout_guide_point::make_shared();

    ui::point notified;

    auto observer = guide_point->chain().perform([&notified](ui::point const &point) { notified = point; }).end();

    guide_point->set_point({1.0f, 2.0f});

    XCTAssertEqual(notified.x, 1.0f);
    XCTAssertEqual(notified.y, 2.0f);

    guide_point->receive_value({3.0f, 4.0f});

    XCTAssertEqual(notified.x, 3.0f);
    XCTAssertEqual(notified.y, 4.0f);
}

- (void)test_point_notify_caller {
    auto point = ui::layout_guide_point::make_shared();

    float notified_x;
    float notified_y;
    ui::point notified_point;

    auto is_all_zero = [](ui::point const &origin) { return origin.x == 0 && origin.y == 0; };

    auto clear_points = [&notified_x, &notified_y, &notified_point]() {
        notified_x = notified_y = 0.0f;
        notified_point.x = notified_point.y = 0.0f;
    };

    auto x_observer = point->x()->chain().perform([&notified_x](float const &value) { notified_x = value; }).end();

    auto y_observer = point->y()->chain().perform([&notified_y](float const &value) { notified_y = value; }).end();

    auto point_observer =
        point->chain().perform([&notified_point](ui::point const &point) { notified_point = point; }).end();

    point->set_point({1.0f, 2.0f});

    XCTAssertEqual(notified_x, 1.0f);
    XCTAssertEqual(notified_y, 2.0f);
    XCTAssertEqual(notified_point.x, 1.0f);
    XCTAssertEqual(notified_point.y, 2.0f);

    clear_points();

    point->push_notify_waiting();

    point->set_point({3.0f, 4.0f});

    XCTAssertEqual(notified_x, 0.0f);
    XCTAssertEqual(notified_y, 0.0f);
    XCTAssertTrue(is_all_zero(notified_point));

    point->push_notify_waiting();

    point->set_point({5.0f, 6.0f});

    XCTAssertEqual(notified_x, 0.0f);
    XCTAssertEqual(notified_y, 0.0f);
    XCTAssertTrue(is_all_zero(notified_point));

    point->pop_notify_waiting();

    point->set_point({7.0f, 8.0f});

    XCTAssertEqual(notified_x, 0.0f);
    XCTAssertEqual(notified_y, 0.0f);
    XCTAssertTrue(is_all_zero(notified_point));

    point->pop_notify_waiting();

    XCTAssertEqual(notified_x, 7.0f);
    XCTAssertEqual(notified_y, 8.0f);
    XCTAssertEqual(notified_point.x, 7.0f);
    XCTAssertEqual(notified_point.y, 8.0f);

    clear_points();

    point->set_point({9.0f, 10.0f});

    XCTAssertEqual(notified_x, 9.0f);
    XCTAssertEqual(notified_y, 10.0f);
    XCTAssertEqual(notified_point.x, 9.0f);
    XCTAssertEqual(notified_point.y, 10.0f);
}

#pragma mark - ui::layout_guide_range

- (void)test_create_range {
    auto range = ui::layout_guide_range::make_shared();

    XCTAssertTrue(range);
    XCTAssertTrue(range->min());
    XCTAssertTrue(range->max());
    XCTAssertEqual(range->min()->value(), 0.0f);
    XCTAssertEqual(range->max()->value(), 0.0f);
    XCTAssertEqual(range->length()->value(), 0.0f);
}

- (void)test_create_range_with_args {
    auto range = ui::layout_guide_range::make_shared({.location = 1.0f, .length = 2.0f});

    XCTAssertTrue(range);
    XCTAssertTrue(range->min());
    XCTAssertTrue(range->max());
    XCTAssertEqual(range->min()->value(), 1.0f);
    XCTAssertEqual(range->max()->value(), 3.0f);
    XCTAssertEqual(range->length()->value(), 2.0f);

    range = ui::layout_guide_range::make_shared({.location = 4.0f, .length = -6.0f});

    XCTAssertEqual(range->min()->value(), -2.0f);
    XCTAssertEqual(range->max()->value(), 4.0f);
    XCTAssertEqual(range->length()->value(), -6.0f);
}

- (void)test_range_accessor {
    auto range = ui::layout_guide_range::make_shared();

    XCTAssertTrue(range->range() == (ui::range{.location = 0.0f, .length = 0.0f}));

    range->set_range({.location = 1.0f, .length = 2.0f});

    XCTAssertTrue(range->range() == (ui::range{1.0f, 2.0f}));
}

- (void)test_chain_range {
    auto guide_range = ui::layout_guide_range::make_shared();

    ui::range notified;

    auto observer = guide_range->chain().perform([&notified](ui::range const &range) { notified = range; }).end();

    guide_range->set_range({1.0f, 2.0f});

    XCTAssertEqual(notified.location, 1.0f);
    XCTAssertEqual(notified.length, 2.0f);

    guide_range->receive_value({3.0f, 4.0f});

    XCTAssertEqual(notified.location, 3.0f);
    XCTAssertEqual(notified.length, 4.0f);
}

- (void)test_range_notify_caller {
    auto range = ui::layout_guide_range::make_shared();

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

    edge notified_new_edge;
    ui::range notified_range;

    auto clear_edges = [&notified_new_edge, &notified_range]() {
        notified_new_edge.clear();
        notified_range = ui::range::zero();
    };

    auto min_observer =
        range->min()
            ->chain()
            .perform([&notified_new_min = notified_new_edge.min](float const &value) { notified_new_min = value; })
            .end();
    auto max_observer =
        range->max()
            ->chain()
            .perform([&notified_new_max = notified_new_edge.max](float const &value) { notified_new_max = value; })
            .end();
    auto length_observer = range->length()
                               ->chain()
                               .perform([&notified_new_length = notified_new_edge.length](float const &value) {
                                   notified_new_length = value;
                               })
                               .end();

    auto observer = range->chain().perform([&notified_range](ui::range const &range) { notified_range = range; }).end();

    range->set_range({1.0f, 2.0f});

    XCTAssertEqual(notified_new_edge.min, 1.0f);
    XCTAssertEqual(notified_new_edge.max, 3.0f);
    XCTAssertEqual(notified_new_edge.length, 2.0f);
    XCTAssertEqual(notified_range.location, 1.0f);
    XCTAssertEqual(notified_range.length, 2.0f);

    clear_edges();

    range->push_notify_waiting();

    range->set_range({3.0f, 4.0f});

    XCTAssertTrue(notified_new_edge.is_all_zero());
    XCTAssertTrue(notified_range == ui::range::zero());

    range->push_notify_waiting();

    range->set_range({5.0f, 6.0f});

    XCTAssertTrue(notified_new_edge.is_all_zero());
    XCTAssertTrue(notified_range == ui::range::zero());

    range->pop_notify_waiting();

    range->set_range({7.0f, 8.0f});

    XCTAssertTrue(notified_new_edge.is_all_zero());
    XCTAssertTrue(notified_range == ui::range::zero());

    range->pop_notify_waiting();

    XCTAssertEqual(notified_new_edge.min, 7.0f);
    XCTAssertEqual(notified_new_edge.max, 15.0f);
    XCTAssertEqual(notified_new_edge.length, 8.0f);
    XCTAssertEqual(notified_range.location, 7.0f);
    XCTAssertEqual(notified_range.length, 8.0f);

    clear_edges();

    range->set_range({9.0f, 10.0f});

    XCTAssertEqual(notified_new_edge.min, 9.0f);
    XCTAssertEqual(notified_new_edge.max, 19.0f);
    XCTAssertEqual(notified_new_edge.length, 10.0f);
    XCTAssertEqual(notified_range.location, 9.0f);
    XCTAssertEqual(notified_range.length, 10.0f);
}

- (void)test_range_set_by_guide {
    auto range = ui::layout_guide_range::make_shared();

    range->max()->set_value(1.0f);

    XCTAssertEqual(range->min()->value(), 0.0f);
    XCTAssertEqual(range->max()->value(), 1.0f);
    XCTAssertEqual(range->length()->value(), 1.0f);

    range->min()->set_value(-1.0f);

    XCTAssertEqual(range->min()->value(), -1.0f);
    XCTAssertEqual(range->max()->value(), 1.0f);
    XCTAssertEqual(range->length()->value(), 2.0f);
}

#pragma mark - ui::layout_guide_rect

- (void)test_create_rect {
    auto rect = ui::layout_guide_rect::make_shared();

    XCTAssertTrue(rect);
    XCTAssertTrue(rect->vertical_range());
    XCTAssertTrue(rect->horizontal_range());
    XCTAssertTrue(rect->left());
    XCTAssertTrue(rect->right());
    XCTAssertTrue(rect->bottom());
    XCTAssertTrue(rect->top());

    XCTAssertEqual(rect->vertical_range()->min()->value(), 0.0f);
    XCTAssertEqual(rect->vertical_range()->max()->value(), 0.0f);
    XCTAssertEqual(rect->horizontal_range()->min()->value(), 0.0f);
    XCTAssertEqual(rect->horizontal_range()->max()->value(), 0.0f);
    XCTAssertEqual(rect->left()->value(), 0.0f);
    XCTAssertEqual(rect->right()->value(), 0.0f);
    XCTAssertEqual(rect->bottom()->value(), 0.0f);
    XCTAssertEqual(rect->top()->value(), 0.0f);
    XCTAssertEqual(rect->width()->value(), 0.0f);
    XCTAssertEqual(rect->height()->value(), 0.0f);
}

- (void)test_create_rect_with_args {
    auto rect = ui::layout_guide_rect::make_shared({.vertical_range = {.location = 11.0f, .length = 1.0f},
                                                    .horizontal_range = {.location = 13.0f, .length = 2.0f}});

    XCTAssertTrue(rect);
    XCTAssertTrue(rect->vertical_range());
    XCTAssertTrue(rect->horizontal_range());
    XCTAssertTrue(rect->left());
    XCTAssertTrue(rect->right());
    XCTAssertTrue(rect->bottom());
    XCTAssertTrue(rect->top());

    XCTAssertEqual(rect->vertical_range()->min()->value(), 11.0f);
    XCTAssertEqual(rect->vertical_range()->max()->value(), 12.0f);
    XCTAssertEqual(rect->horizontal_range()->min()->value(), 13.0f);
    XCTAssertEqual(rect->horizontal_range()->max()->value(), 15.0f);
    XCTAssertEqual(rect->bottom()->value(), 11.0f);
    XCTAssertEqual(rect->top()->value(), 12.0f);
    XCTAssertEqual(rect->left()->value(), 13.0f);
    XCTAssertEqual(rect->right()->value(), 15.0f);
    XCTAssertEqual(rect->width()->value(), 2.0f);
    XCTAssertEqual(rect->height()->value(), 1.0f);
}

- (void)test_rect_set_vertical_ranges {
    auto rect = ui::layout_guide_rect::make_shared();

    rect->set_vertical_range({.location = 100.0f, .length = 101.0f});

    XCTAssertEqual(rect->bottom()->value(), 100.0f);
    XCTAssertEqual(rect->top()->value(), 201.0f);
    XCTAssertEqual(rect->left()->value(), 0.0f);
    XCTAssertEqual(rect->right()->value(), 0.0f);
    XCTAssertEqual(rect->width()->value(), 0.0f);
    XCTAssertEqual(rect->height()->value(), 101.0f);
}

- (void)test_rect_set_horizontal_ranges {
    auto rect = ui::layout_guide_rect::make_shared();

    rect->set_horizontal_range({.location = 300.0f, .length = 102.0f});

    XCTAssertEqual(rect->bottom()->value(), 0.0f);
    XCTAssertEqual(rect->top()->value(), 0.0f);
    XCTAssertEqual(rect->left()->value(), 300.0f);
    XCTAssertEqual(rect->right()->value(), 402.0f);
    XCTAssertEqual(rect->width()->value(), 102.0f);
    XCTAssertEqual(rect->height()->value(), 0.0f);
}

- (void)test_rect_set_ranges {
    auto rect = ui::layout_guide_rect::make_shared();

    rect->set_ranges({.vertical_range = {.location = 11.0f, .length = 1.0f},
                      .horizontal_range = {.location = 13.0f, .length = 2.0f}});

    XCTAssertEqual(rect->bottom()->value(), 11.0f);
    XCTAssertEqual(rect->top()->value(), 12.0f);
    XCTAssertEqual(rect->left()->value(), 13.0f);
    XCTAssertEqual(rect->right()->value(), 15.0f);
    XCTAssertEqual(rect->width()->value(), 2.0f);
    XCTAssertEqual(rect->height()->value(), 1.0f);
}

- (void)test_rect_set_region {
    auto rect = ui::layout_guide_rect::make_shared();

    rect->set_region({.origin = {1.0f, 2.0f}, .size = {3.0f, 4.0f}});

    XCTAssertEqual(rect->bottom()->value(), 2.0f);
    XCTAssertEqual(rect->top()->value(), 6.0f);
    XCTAssertEqual(rect->left()->value(), 1.0f);
    XCTAssertEqual(rect->right()->value(), 4.0f);
    XCTAssertEqual(rect->width()->value(), 3.0f);
    XCTAssertEqual(rect->height()->value(), 4.0f);
}

- (void)test_chain_rect {
    auto guide_rect = ui::layout_guide_rect::make_shared();

    ui::region notified;

    auto observer = guide_rect->chain().perform([&notified](ui::region const &region) { notified = region; }).end();

    guide_rect->set_region({.origin = {1.0f, 2.0f}, .size = {3.0f, 4.0f}});

    XCTAssertEqual(notified.origin.x, 1.0f);
    XCTAssertEqual(notified.origin.y, 2.0f);
    XCTAssertEqual(notified.size.width, 3.0f);
    XCTAssertEqual(notified.size.height, 4.0f);

    guide_rect->receive_value({.origin = {5.0f, 6.0f}, .size = {7.0f, 8.0f}});

    XCTAssertEqual(notified.origin.x, 5.0f);
    XCTAssertEqual(notified.origin.y, 6.0f);
    XCTAssertEqual(notified.size.width, 7.0f);
    XCTAssertEqual(notified.size.height, 8.0f);
}

- (void)test_rect_notify_caller {
    auto rect = ui::layout_guide_rect::make_shared();

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

    edge notified_new_edge;
    ui::region notified_region;

    auto clear_edges = [&notified_new_edge, &notified_region]() {
        notified_new_edge.clear();
        notified_region = ui::region::zero();
    };

    auto left_observer =
        rect->left()
            ->chain()
            .perform([&notified_new_left = notified_new_edge.left](float const &value) { notified_new_left = value; })
            .end();
    auto right_observer = rect->right()
                              ->chain()
                              .perform([&notified_new_right = notified_new_edge.right](float const &value) {
                                  notified_new_right = value;
                              })
                              .end();
    auto bottom_observer = rect->bottom()
                               ->chain()
                               .perform([&notified_new_bottom = notified_new_edge.bottom](float const &value) {
                                   notified_new_bottom = value;
                               })
                               .end();
    auto top_observer =
        rect->top()
            ->chain()
            .perform([&notified_new_top = notified_new_edge.top](float const &value) { notified_new_top = value; })
            .end();
    auto width_observer = rect->width()
                              ->chain()
                              .perform([&notified_new_width = notified_new_edge.width](float const &value) {
                                  notified_new_width = value;
                              })
                              .end();
    auto height_observer = rect->height()
                               ->chain()
                               .perform([&notified_new_height = notified_new_edge.height](float const &value) {
                                   notified_new_height = value;
                               })
                               .end();
    auto region_observer =
        rect->chain().perform([&notified_region](ui::region const &value) { notified_region = value; }).end();

    rect->set_region({.origin = {1.0f, 2.0f}, .size = {3.0f, 4.0f}});

    XCTAssertEqual(notified_new_edge.left, 1.0f);
    XCTAssertEqual(notified_new_edge.right, 4.0f);
    XCTAssertEqual(notified_new_edge.bottom, 2.0f);
    XCTAssertEqual(notified_new_edge.top, 6.0f);
    XCTAssertEqual(notified_new_edge.width, 3.0f);
    XCTAssertEqual(notified_new_edge.height, 4.0f);
    XCTAssertEqual(notified_region.origin.x, 1.0f);
    XCTAssertEqual(notified_region.origin.y, 2.0f);
    XCTAssertEqual(notified_region.size.width, 3.0f);
    XCTAssertEqual(notified_region.size.height, 4.0f);

    clear_edges();

    rect->push_notify_waiting();

    rect->set_region({.origin = {5.0f, 6.0f}, .size = {7.0f, 8.0f}});

    XCTAssertTrue(notified_new_edge.is_all_zero());
    XCTAssertTrue(notified_region == ui::region::zero());

    rect->push_notify_waiting();

    rect->set_region({.origin = {9.0f, 10.0f}, .size = {11.0f, 12.0f}});

    XCTAssertTrue(notified_new_edge.is_all_zero());
    XCTAssertTrue(notified_region == ui::region::zero());

    rect->pop_notify_waiting();

    rect->set_region({.origin = {13.0f, 14.0f}, .size = {15.0f, 16.0f}});

    XCTAssertTrue(notified_new_edge.is_all_zero());
    XCTAssertTrue(notified_region == ui::region::zero());

    rect->pop_notify_waiting();

    XCTAssertEqual(notified_new_edge.left, 13.0f);
    XCTAssertEqual(notified_new_edge.right, 28.0f);
    XCTAssertEqual(notified_new_edge.bottom, 14.0f);
    XCTAssertEqual(notified_new_edge.top, 30.0f);
    XCTAssertEqual(notified_new_edge.width, 15.0f);
    XCTAssertEqual(notified_new_edge.height, 16.0f);

    XCTAssertEqual(notified_region.origin.x, 13.0f);
    XCTAssertEqual(notified_region.origin.y, 14.0f);
    XCTAssertEqual(notified_region.size.width, 15.0f);
    XCTAssertEqual(notified_region.size.height, 16.0f);

    clear_edges();

    rect->set_region({.origin = {17.0f, 18.0f}, .size = {19.0f, 20.0f}});

    XCTAssertEqual(notified_new_edge.left, 17.0f);
    XCTAssertEqual(notified_new_edge.right, 36.0f);
    XCTAssertEqual(notified_new_edge.bottom, 18.0f);
    XCTAssertEqual(notified_new_edge.top, 38.0f);
    XCTAssertEqual(notified_new_edge.width, 19.0f);
    XCTAssertEqual(notified_new_edge.height, 20.0f);

    XCTAssertEqual(notified_region.origin.x, 17.0f);
    XCTAssertEqual(notified_region.origin.y, 18.0f);
    XCTAssertEqual(notified_region.size.width, 19.0f);
    XCTAssertEqual(notified_region.size.height, 20.0f);
}

- (void)test_rect_set_by_guide {
    auto rect = ui::layout_guide_rect::make_shared();

    // horizontal

    rect->right()->set_value(1.0f);

    XCTAssertEqual(rect->left()->value(), 0.0f);
    XCTAssertEqual(rect->right()->value(), 1.0f);
    XCTAssertEqual(rect->width()->value(), 1.0f);

    rect->left()->set_value(-1.0f);

    XCTAssertEqual(rect->left()->value(), -1.0f);
    XCTAssertEqual(rect->right()->value(), 1.0f);
    XCTAssertEqual(rect->width()->value(), 2.0f);

    // vertical

    rect->top()->set_value(1.0f);

    XCTAssertEqual(rect->bottom()->value(), 0.0f);
    XCTAssertEqual(rect->top()->value(), 1.0f);
    XCTAssertEqual(rect->height()->value(), 1.0f);

    rect->bottom()->set_value(-1.0f);

    XCTAssertEqual(rect->bottom()->value(), -1.0f);
    XCTAssertEqual(rect->top()->value(), 1.0f);
    XCTAssertEqual(rect->height()->value(), 2.0f);
}

@end
