//
//  yas_ui_layout_tests.mm
//

#import <XCTest/XCTest.h>
#import <ui/ui.h>

using namespace yas;
using namespace yas::ui;

@interface yas_ui_layout_guide_tests : XCTestCase

@end

@implementation yas_ui_layout_guide_tests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

#pragma mark - layout_value_guide

- (void)test_create_guide {
    auto guide = layout_value_guide::make_shared();

    XCTAssertTrue(guide);
    XCTAssertEqual(guide->value(), 0.0f);
}

- (void)test_create_guide_with_value {
    auto guide = layout_value_guide::make_shared(1.0f);

    XCTAssertTrue(guide);
    XCTAssertEqual(guide->value(), 1.0f);
}

- (void)test_notify_caller {
    auto guide = layout_value_guide::make_shared();

    std::vector<float> notified;

    auto canceller = guide->observe([&notified](float const &value) { notified.push_back(value); }).end();

    XCTAssertEqual(notified.size(), 0);

    guide->set_value(1.0f);

    XCTAssertEqual(notified.size(), 1);
    XCTAssertEqual(notified.at(0), 1.0f);

    notified.clear();

    guide->push_notify_waiting();
    guide->set_value(2.0f);

    XCTAssertEqual(notified.size(), 0);

    guide->push_notify_waiting();
    guide->set_value(3.0f);

    XCTAssertEqual(notified.size(), 0);

    guide->pop_notify_waiting();
    guide->set_value(4.0f);

    XCTAssertEqual(notified.size(), 0);

    guide->pop_notify_waiting();

    XCTAssertEqual(notified.size(), 1);
    XCTAssertEqual(notified.at(0), 4.0f);

    notified.clear();

    guide->set_value(5.0f);

    XCTAssertEqual(notified.size(), 1);
    XCTAssertEqual(notified.at(0), 5.0f);
}

- (void)test_notify_caller_canceled {
    auto guide = layout_value_guide::make_shared(1.0f);

    bool called = false;

    auto canceller = guide->observe([&called](auto const &) { called = true; }).end();

    guide->push_notify_waiting();

    guide->set_value(2.0f);
    guide->set_value(1.0f);

    guide->pop_notify_waiting();

    XCTAssertFalse(called);
}

#pragma mark - layout_guide_point

- (void)test_create_point {
    auto point = layout_point_guide::make_shared();

    XCTAssertTrue(point);
    XCTAssertTrue(point->x());
    XCTAssertTrue(point->y());
    XCTAssertEqual(point->x()->value(), 0.0f);
    XCTAssertEqual(point->y()->value(), 0.0f);
}

- (void)test_create_point_with_args {
    auto point = layout_point_guide::make_shared({1.0f, 2.0f});

    XCTAssertTrue(point);
    XCTAssertTrue(point->x());
    XCTAssertTrue(point->y());
    XCTAssertEqual(point->x()->value(), 1.0f);
    XCTAssertEqual(point->y()->value(), 2.0f);
}

- (void)test_point_accessor {
    auto point = layout_point_guide::make_shared();

    XCTAssertTrue(point->point() == (ui::point{0.0f, 0.0f}));

    point->set_point({1.0f, -1.0f});

    XCTAssertTrue(point->point() == (ui::point{1.0f, -1.0f}));
}

- (void)test_observe_point {
    auto guide_point = layout_point_guide::make_shared();

    std::vector<point> notified;

    auto canceller = guide_point->observe([&notified](point const &point) { notified.push_back(point); }).end();

    guide_point->set_point({1.0f, 2.0f});

    XCTAssertEqual(notified.size(), 1);
    XCTAssertEqual(notified.at(0).x, 1.0f);
    XCTAssertEqual(notified.at(0).y, 2.0f);

    guide_point->x()->set_value(3.0f);

    XCTAssertEqual(notified.size(), 2);
    XCTAssertEqual(notified.at(1).x, 3.0f);
    XCTAssertEqual(notified.at(1).y, 2.0f);

    guide_point->y()->set_value(4.0f);

    XCTAssertEqual(notified.size(), 3);
    XCTAssertEqual(notified.at(2).x, 3.0f);
    XCTAssertEqual(notified.at(2).y, 4.0f);
}

- (void)test_point_notify_caller {
    auto point = layout_point_guide::make_shared();

    std::vector<float> notified_xs;
    std::vector<float> notified_ys;
    std::vector<ui::point> notified_points;

    auto clear_points = [&notified_xs, &notified_ys, &notified_points]() {
        notified_xs.clear();
        notified_ys.clear();
        notified_points.clear();
    };

    auto x_observer = point->x()->observe([&notified_xs](float const &value) { notified_xs.push_back(value); }).end();

    auto y_observer = point->y()->observe([&notified_ys](float const &value) { notified_ys.push_back(value); }).end();

    auto point_observer =
        point->observe([&notified_points](ui::point const &point) { notified_points.push_back(point); }).end();

    point->set_point({1.0f, 2.0f});

    XCTAssertEqual(notified_xs.size(), 1);
    XCTAssertEqual(notified_xs.at(0), 1.0f);
    XCTAssertEqual(notified_ys.size(), 1);
    XCTAssertEqual(notified_ys.at(0), 2.0f);
    XCTAssertEqual(notified_points.size(), 1);
    XCTAssertEqual(notified_points.at(0).x, 1.0f);
    XCTAssertEqual(notified_points.at(0).y, 2.0f);

    clear_points();

    point->push_notify_waiting();

    point->set_point({3.0f, 4.0f});

    XCTAssertEqual(notified_xs.size(), 0);
    XCTAssertEqual(notified_ys.size(), 0);
    XCTAssertEqual(notified_points.size(), 0);

    point->push_notify_waiting();

    point->set_point({5.0f, 6.0f});

    XCTAssertEqual(notified_xs.size(), 0);
    XCTAssertEqual(notified_ys.size(), 0);
    XCTAssertEqual(notified_points.size(), 0);

    point->pop_notify_waiting();

    point->set_point({7.0f, 8.0f});

    XCTAssertEqual(notified_xs.size(), 0);
    XCTAssertEqual(notified_ys.size(), 0);
    XCTAssertEqual(notified_points.size(), 0);

    point->pop_notify_waiting();

    XCTAssertEqual(notified_xs.size(), 1);
    XCTAssertEqual(notified_xs.at(0), 7.0f);
    XCTAssertEqual(notified_ys.size(), 1);
    XCTAssertEqual(notified_ys.at(0), 8.0f);
    XCTAssertEqual(notified_points.size(), 1);
    XCTAssertEqual(notified_points.at(0).x, 7.0f);
    XCTAssertEqual(notified_points.at(0).y, 8.0f);

    clear_points();

    point->set_point({9.0f, 10.0f});

    XCTAssertEqual(notified_xs.size(), 1);
    XCTAssertEqual(notified_xs.at(0), 9.0f);
    XCTAssertEqual(notified_ys.size(), 1);
    XCTAssertEqual(notified_ys.at(0), 10.0f);
    XCTAssertEqual(notified_points.size(), 1);
    XCTAssertEqual(notified_points.at(0).x, 9.0f);
    XCTAssertEqual(notified_points.at(0).y, 10.0f);
}

#pragma mark - layout_guide_range

- (void)test_create_range {
    auto range = layout_range_guide::make_shared();

    XCTAssertTrue(range);
    XCTAssertTrue(range->min());
    XCTAssertTrue(range->max());
    XCTAssertEqual(range->min()->value(), 0.0f);
    XCTAssertEqual(range->max()->value(), 0.0f);
    XCTAssertEqual(range->length()->value(), 0.0f);
}

- (void)test_create_range_with_args {
    auto range = layout_range_guide::make_shared({.location = 1.0f, .length = 2.0f});

    XCTAssertTrue(range);
    XCTAssertTrue(range->min());
    XCTAssertTrue(range->max());
    XCTAssertEqual(range->min()->value(), 1.0f);
    XCTAssertEqual(range->max()->value(), 3.0f);
    XCTAssertEqual(range->length()->value(), 2.0f);

    range = layout_range_guide::make_shared({.location = 4.0f, .length = -6.0f});

    XCTAssertEqual(range->min()->value(), -2.0f);
    XCTAssertEqual(range->max()->value(), 4.0f);
    XCTAssertEqual(range->length()->value(), -6.0f);
}

- (void)test_range_accessor {
    auto range = layout_range_guide::make_shared();

    XCTAssertTrue(range->range() == (ui::range{.location = 0.0f, .length = 0.0f}));

    range->set_range({.location = 1.0f, .length = 2.0f});

    XCTAssertTrue(range->range() == (ui::range{1.0f, 2.0f}));
}

- (void)test_observe_range {
    auto guide_range = layout_range_guide::make_shared();

    std::vector<range> notified;

    auto observer = guide_range->observe([&notified](range const &range) { notified.push_back(range); }).end();

    guide_range->set_range({1.0f, 2.0f});

    XCTAssertEqual(notified.size(), 1);
    XCTAssertEqual(notified.at(0).location, 1.0f);
    XCTAssertEqual(notified.at(0).length, 2.0f);

    guide_range->min()->set_value(0.0f);

    XCTAssertEqual(notified.size(), 2);
    XCTAssertEqual(notified.at(1).location, 0.0f);
    XCTAssertEqual(notified.at(1).length, 3.0f);

    guide_range->max()->set_value(4.0f);

    XCTAssertEqual(notified.size(), 3);
    XCTAssertEqual(notified.at(2).location, 0.0f);
    XCTAssertEqual(notified.at(2).length, 4.0f);
}

- (void)test_range_notify_caller {
    auto range = layout_range_guide::make_shared();

    std::vector<float> notified_mins;
    std::vector<float> notified_maxs;
    std::vector<float> notified_lengths;
    std::vector<ui::range> notified_ranges;

    auto clear_notified = [&notified_mins, &notified_maxs, &notified_lengths, &notified_ranges]() {
        notified_mins.clear();
        notified_maxs.clear();
        notified_lengths.clear();
        notified_ranges.clear();
    };

    auto min_observer =
        range->min()->observe([&notified_mins](float const &value) { notified_mins.push_back(value); }).end();
    auto max_observer =
        range->max()->observe([&notified_maxs](float const &value) { notified_maxs.push_back(value); }).end();
    auto length_observer =
        range->length()->observe([&notified_lengths](float const &value) { notified_lengths.push_back(value); }).end();

    auto observer =
        range->observe([&notified_ranges](ui::range const &range) { notified_ranges.push_back(range); }).end();

    range->set_range({1.0f, 2.0f});

    XCTAssertEqual(notified_mins.size(), 1);
    XCTAssertEqual(notified_mins.at(0), 1.0f);
    XCTAssertEqual(notified_maxs.size(), 1);
    XCTAssertEqual(notified_maxs.at(0), 3.0f);
    XCTAssertEqual(notified_lengths.size(), 1);
    XCTAssertEqual(notified_lengths.at(0), 2.0f);
    XCTAssertEqual(notified_ranges.size(), 1);
    XCTAssertEqual(notified_ranges.at(0).location, 1.0f);
    XCTAssertEqual(notified_ranges.at(0).length, 2.0f);

    clear_notified();

    range->push_notify_waiting();

    range->set_range({3.0f, 4.0f});

    XCTAssertEqual(notified_mins.size(), 0);
    XCTAssertEqual(notified_maxs.size(), 0);
    XCTAssertEqual(notified_lengths.size(), 0);
    XCTAssertEqual(notified_ranges.size(), 0);

    range->push_notify_waiting();

    range->set_range({5.0f, 6.0f});

    XCTAssertEqual(notified_mins.size(), 0);
    XCTAssertEqual(notified_maxs.size(), 0);
    XCTAssertEqual(notified_lengths.size(), 0);
    XCTAssertEqual(notified_ranges.size(), 0);

    range->pop_notify_waiting();

    range->set_range({7.0f, 8.0f});

    XCTAssertEqual(notified_mins.size(), 0);
    XCTAssertEqual(notified_maxs.size(), 0);
    XCTAssertEqual(notified_lengths.size(), 0);
    XCTAssertEqual(notified_ranges.size(), 0);

    range->pop_notify_waiting();

    XCTAssertEqual(notified_mins.size(), 1);
    XCTAssertEqual(notified_mins.at(0), 7.0f);
    XCTAssertEqual(notified_maxs.size(), 1);
    XCTAssertEqual(notified_maxs.at(0), 15.0f);
    XCTAssertEqual(notified_lengths.size(), 1);
    XCTAssertEqual(notified_lengths.at(0), 8.0f);
    XCTAssertEqual(notified_ranges.size(), 1);
    XCTAssertEqual(notified_ranges.at(0).location, 7.0f);
    XCTAssertEqual(notified_ranges.at(0).length, 8.0f);

    clear_notified();

    range->set_range({9.0f, 10.0f});

    XCTAssertEqual(notified_mins.size(), 1);
    XCTAssertEqual(notified_mins.at(0), 9.0f);
    XCTAssertEqual(notified_maxs.size(), 1);
    XCTAssertEqual(notified_maxs.at(0), 19.0f);
    XCTAssertEqual(notified_lengths.size(), 1);
    XCTAssertEqual(notified_lengths.at(0), 10.0f);
    XCTAssertEqual(notified_ranges.size(), 1);
    XCTAssertEqual(notified_ranges.at(0).location, 9.0f);
    XCTAssertEqual(notified_ranges.at(0).length, 10.0f);
}

- (void)test_range_set_by_guide {
    auto const range = layout_range_guide::make_shared();

    range->max()->set_value(1.0f);

    XCTAssertEqual(range->min()->value(), 0.0f);
    XCTAssertEqual(range->max()->value(), 1.0f);
    XCTAssertEqual(range->length()->value(), 1.0f);

    range->min()->set_value(-1.0f);

    XCTAssertEqual(range->min()->value(), -1.0f);
    XCTAssertEqual(range->max()->value(), 1.0f);
    XCTAssertEqual(range->length()->value(), 2.0f);
}

#pragma mark - layout_region_guide

- (void)test_create_region {
    auto const guide = layout_region_guide::make_shared();

    XCTAssertTrue(guide);
    XCTAssertTrue(guide->vertical_range());
    XCTAssertTrue(guide->horizontal_range());
    XCTAssertTrue(guide->left());
    XCTAssertTrue(guide->right());
    XCTAssertTrue(guide->bottom());
    XCTAssertTrue(guide->top());

    XCTAssertEqual(guide->vertical_range()->min()->value(), 0.0f);
    XCTAssertEqual(guide->vertical_range()->max()->value(), 0.0f);
    XCTAssertEqual(guide->horizontal_range()->min()->value(), 0.0f);
    XCTAssertEqual(guide->horizontal_range()->max()->value(), 0.0f);
    XCTAssertEqual(guide->left()->value(), 0.0f);
    XCTAssertEqual(guide->right()->value(), 0.0f);
    XCTAssertEqual(guide->bottom()->value(), 0.0f);
    XCTAssertEqual(guide->top()->value(), 0.0f);
    XCTAssertEqual(guide->width()->value(), 0.0f);
    XCTAssertEqual(guide->height()->value(), 0.0f);
}

- (void)test_create_region_with_args {
    auto const guide = layout_region_guide::make_shared(
        {.vertical = {.location = 11.0f, .length = 1.0f}, .horizontal = {.location = 13.0f, .length = 2.0f}});

    XCTAssertTrue(guide);
    XCTAssertTrue(guide->vertical_range());
    XCTAssertTrue(guide->horizontal_range());
    XCTAssertTrue(guide->left());
    XCTAssertTrue(guide->right());
    XCTAssertTrue(guide->bottom());
    XCTAssertTrue(guide->top());

    XCTAssertEqual(guide->vertical_range()->min()->value(), 11.0f);
    XCTAssertEqual(guide->vertical_range()->max()->value(), 12.0f);
    XCTAssertEqual(guide->horizontal_range()->min()->value(), 13.0f);
    XCTAssertEqual(guide->horizontal_range()->max()->value(), 15.0f);
    XCTAssertEqual(guide->bottom()->value(), 11.0f);
    XCTAssertEqual(guide->top()->value(), 12.0f);
    XCTAssertEqual(guide->left()->value(), 13.0f);
    XCTAssertEqual(guide->right()->value(), 15.0f);
    XCTAssertEqual(guide->width()->value(), 2.0f);
    XCTAssertEqual(guide->height()->value(), 1.0f);
}

- (void)test_region_set_vertical_ranges {
    auto const guide = layout_region_guide::make_shared();

    guide->set_vertical_range({.location = 100.0f, .length = 101.0f});

    XCTAssertEqual(guide->bottom()->value(), 100.0f);
    XCTAssertEqual(guide->top()->value(), 201.0f);
    XCTAssertEqual(guide->left()->value(), 0.0f);
    XCTAssertEqual(guide->right()->value(), 0.0f);
    XCTAssertEqual(guide->width()->value(), 0.0f);
    XCTAssertEqual(guide->height()->value(), 101.0f);
}

- (void)test_region_set_horizontal_ranges {
    auto const guide = layout_region_guide::make_shared();

    guide->set_horizontal_range({.location = 300.0f, .length = 102.0f});

    XCTAssertEqual(guide->bottom()->value(), 0.0f);
    XCTAssertEqual(guide->top()->value(), 0.0f);
    XCTAssertEqual(guide->left()->value(), 300.0f);
    XCTAssertEqual(guide->right()->value(), 402.0f);
    XCTAssertEqual(guide->width()->value(), 102.0f);
    XCTAssertEqual(guide->height()->value(), 0.0f);
}

- (void)test_region_set_ranges {
    auto const guide = layout_region_guide::make_shared();

    guide->set_ranges(
        {.vertical = {.location = 11.0f, .length = 1.0f}, .horizontal = {.location = 13.0f, .length = 2.0f}});

    XCTAssertEqual(guide->bottom()->value(), 11.0f);
    XCTAssertEqual(guide->top()->value(), 12.0f);
    XCTAssertEqual(guide->left()->value(), 13.0f);
    XCTAssertEqual(guide->right()->value(), 15.0f);
    XCTAssertEqual(guide->width()->value(), 2.0f);
    XCTAssertEqual(guide->height()->value(), 1.0f);
}

- (void)test_region_set_region {
    auto const guide = layout_region_guide::make_shared();

    guide->set_region({.origin = {1.0f, 2.0f}, .size = {3.0f, 4.0f}});

    XCTAssertEqual(guide->bottom()->value(), 2.0f);
    XCTAssertEqual(guide->top()->value(), 6.0f);
    XCTAssertEqual(guide->left()->value(), 1.0f);
    XCTAssertEqual(guide->right()->value(), 4.0f);
    XCTAssertEqual(guide->width()->value(), 3.0f);
    XCTAssertEqual(guide->height()->value(), 4.0f);
}

- (void)test_observe_region {
    auto const guide = layout_region_guide::make_shared();

    std::vector<region> notified;

    auto canceller = guide->observe([&notified](region const &region) { notified.push_back(region); }).end();

    guide->set_region({.origin = {1.0f, 2.0f}, .size = {3.0f, 4.0f}});

    XCTAssertEqual(notified.size(), 1);
    XCTAssertEqual(notified.at(0).origin.x, 1.0f);
    XCTAssertEqual(notified.at(0).origin.y, 2.0f);
    XCTAssertEqual(notified.at(0).size.width, 3.0f);
    XCTAssertEqual(notified.at(0).size.height, 4.0f);

    guide->left()->set_value(0.0f);

    XCTAssertEqual(notified.size(), 2);
    XCTAssertEqual(notified.at(1).origin.x, 0.0f);
    XCTAssertEqual(notified.at(1).origin.y, 2.0f);
    XCTAssertEqual(notified.at(1).size.width, 4.0f);
    XCTAssertEqual(notified.at(1).size.height, 4.0f);

    guide->vertical_range()->set_range({8.0f, 16.0f});

    XCTAssertEqual(notified.size(), 3);
    XCTAssertEqual(notified.at(2).origin.x, 0.0f);
    XCTAssertEqual(notified.at(2).origin.y, 8.0f);
    XCTAssertEqual(notified.at(2).size.width, 4.0f);
    XCTAssertEqual(notified.at(2).size.height, 16.0f);

    canceller->cancel();
}

- (void)test_region_notify_caller {
    auto const guide = layout_region_guide::make_shared();

    std::vector<float> notified_lefts;
    std::vector<float> notified_rights;
    std::vector<float> notified_bottoms;
    std::vector<float> notified_tops;
    std::vector<float> notified_widths;
    std::vector<float> notified_heights;
    std::vector<ui::region> notified_regions;

    auto const clear_notified = [&notified_lefts, &notified_rights, &notified_bottoms, &notified_tops, &notified_widths,
                                 &notified_heights, &notified_regions]() {
        notified_lefts.clear();
        notified_rights.clear();
        notified_bottoms.clear();
        notified_tops.clear();
        notified_widths.clear();
        notified_heights.clear();
        notified_regions.clear();
    };

    auto left_observer =
        guide->left()->observe([&notified_lefts](float const &value) { notified_lefts.push_back(value); }).end();
    auto right_observer =
        guide->right()->observe([&notified_rights](float const &value) { notified_rights.push_back(value); }).end();
    auto bottom_observer =
        guide->bottom()->observe([&notified_bottoms](float const &value) { notified_bottoms.push_back(value); }).end();
    auto top_observer =
        guide->top()->observe([&notified_tops](float const &value) { notified_tops.push_back(value); }).end();
    auto width_observer =
        guide->width()->observe([&notified_widths](float const &value) { notified_widths.push_back(value); }).end();
    auto height_observer =
        guide->height()->observe([&notified_heights](float const &value) { notified_heights.push_back(value); }).end();
    auto region_observer =
        guide->observe([&notified_regions](region const &value) { notified_regions.push_back(value); }).end();

    guide->set_region({.origin = {1.0f, 2.0f}, .size = {3.0f, 4.0f}});

    XCTAssertEqual(notified_lefts.size(), 1);
    XCTAssertEqual(notified_lefts.at(0), 1.0f);
    XCTAssertEqual(notified_rights.size(), 1);
    XCTAssertEqual(notified_rights.at(0), 4.0f);
    XCTAssertEqual(notified_bottoms.size(), 1);
    XCTAssertEqual(notified_bottoms.at(0), 2.0f);
    XCTAssertEqual(notified_tops.size(), 1);
    XCTAssertEqual(notified_tops.at(0), 6.0f);
    XCTAssertEqual(notified_widths.size(), 1);
    XCTAssertEqual(notified_widths.at(0), 3.0f);
    XCTAssertEqual(notified_heights.size(), 1);
    XCTAssertEqual(notified_heights.at(0), 4.0f);
    XCTAssertEqual(notified_regions.size(), 1);
    XCTAssertEqual(notified_regions.at(0).origin.x, 1.0f);
    XCTAssertEqual(notified_regions.at(0).origin.y, 2.0f);
    XCTAssertEqual(notified_regions.at(0).size.width, 3.0f);
    XCTAssertEqual(notified_regions.at(0).size.height, 4.0f);

    clear_notified();

    guide->push_notify_waiting();

    guide->set_region({.origin = {5.0f, 6.0f}, .size = {7.0f, 8.0f}});

    XCTAssertEqual(notified_lefts.size(), 0);
    XCTAssertEqual(notified_rights.size(), 0);
    XCTAssertEqual(notified_bottoms.size(), 0);
    XCTAssertEqual(notified_tops.size(), 0);
    XCTAssertEqual(notified_widths.size(), 0);
    XCTAssertEqual(notified_heights.size(), 0);
    XCTAssertEqual(notified_regions.size(), 0);

    guide->push_notify_waiting();

    guide->set_region({.origin = {9.0f, 10.0f}, .size = {11.0f, 12.0f}});

    XCTAssertEqual(notified_lefts.size(), 0);
    XCTAssertEqual(notified_rights.size(), 0);
    XCTAssertEqual(notified_bottoms.size(), 0);
    XCTAssertEqual(notified_tops.size(), 0);
    XCTAssertEqual(notified_widths.size(), 0);
    XCTAssertEqual(notified_heights.size(), 0);
    XCTAssertEqual(notified_regions.size(), 0);

    guide->pop_notify_waiting();

    guide->set_region({.origin = {13.0f, 14.0f}, .size = {15.0f, 16.0f}});

    XCTAssertEqual(notified_lefts.size(), 0);
    XCTAssertEqual(notified_rights.size(), 0);
    XCTAssertEqual(notified_bottoms.size(), 0);
    XCTAssertEqual(notified_tops.size(), 0);
    XCTAssertEqual(notified_widths.size(), 0);
    XCTAssertEqual(notified_heights.size(), 0);
    XCTAssertEqual(notified_regions.size(), 0);

    guide->pop_notify_waiting();

    XCTAssertEqual(notified_lefts.size(), 1);
    XCTAssertEqual(notified_lefts.at(0), 13.0f);
    XCTAssertEqual(notified_rights.size(), 1);
    XCTAssertEqual(notified_rights.at(0), 28.0f);
    XCTAssertEqual(notified_bottoms.size(), 1);
    XCTAssertEqual(notified_bottoms.at(0), 14.0f);
    XCTAssertEqual(notified_tops.size(), 1);
    XCTAssertEqual(notified_tops.at(0), 30.0f);
    XCTAssertEqual(notified_widths.size(), 1);
    XCTAssertEqual(notified_widths.at(0), 15.0f);
    XCTAssertEqual(notified_heights.size(), 1);
    XCTAssertEqual(notified_heights.at(0), 16.0f);
    XCTAssertEqual(notified_regions.size(), 1);
    XCTAssertEqual(notified_regions.at(0).origin.x, 13.0f);
    XCTAssertEqual(notified_regions.at(0).origin.y, 14.0f);
    XCTAssertEqual(notified_regions.at(0).size.width, 15.0f);
    XCTAssertEqual(notified_regions.at(0).size.height, 16.0f);

    clear_notified();

    guide->set_region({.origin = {17.0f, 18.0f}, .size = {19.0f, 20.0f}});

    XCTAssertEqual(notified_lefts.size(), 1);
    XCTAssertEqual(notified_lefts.at(0), 17.0f);
    XCTAssertEqual(notified_rights.size(), 1);
    XCTAssertEqual(notified_rights.at(0), 36.0f);
    XCTAssertEqual(notified_bottoms.size(), 1);
    XCTAssertEqual(notified_bottoms.at(0), 18.0f);
    XCTAssertEqual(notified_tops.size(), 1);
    XCTAssertEqual(notified_tops.at(0), 38.0f);
    XCTAssertEqual(notified_widths.size(), 1);
    XCTAssertEqual(notified_widths.at(0), 19.0f);
    XCTAssertEqual(notified_heights.size(), 1);
    XCTAssertEqual(notified_heights.at(0), 20.0f);
    XCTAssertEqual(notified_regions.size(), 1);
    XCTAssertEqual(notified_regions.at(0).origin.x, 17.0f);
    XCTAssertEqual(notified_regions.at(0).origin.y, 18.0f);
    XCTAssertEqual(notified_regions.at(0).size.width, 19.0f);
    XCTAssertEqual(notified_regions.at(0).size.height, 20.0f);
}

- (void)test_region_set_by_guide {
    auto const guide = layout_region_guide::make_shared();

    // horizontal

    guide->right()->set_value(1.0f);

    XCTAssertEqual(guide->left()->value(), 0.0f);
    XCTAssertEqual(guide->right()->value(), 1.0f);
    XCTAssertEqual(guide->width()->value(), 1.0f);

    guide->left()->set_value(-1.0f);

    XCTAssertEqual(guide->left()->value(), -1.0f);
    XCTAssertEqual(guide->right()->value(), 1.0f);
    XCTAssertEqual(guide->width()->value(), 2.0f);

    // vertical

    guide->top()->set_value(1.0f);

    XCTAssertEqual(guide->bottom()->value(), 0.0f);
    XCTAssertEqual(guide->top()->value(), 1.0f);
    XCTAssertEqual(guide->height()->value(), 1.0f);

    guide->bottom()->set_value(-1.0f);

    XCTAssertEqual(guide->bottom()->value(), -1.0f);
    XCTAssertEqual(guide->top()->value(), 1.0f);
    XCTAssertEqual(guide->height()->value(), 2.0f);
}

@end
