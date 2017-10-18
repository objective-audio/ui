//
//  yas_ui_layout_actions_tests.mm
//

#import <XCTest/XCTest.h>
#import "yas_ui_layout_actions.h"
#import "yas_ui_layout_guide.h"

using namespace yas;
using namespace std::chrono_literals;

@interface yas_ui_layout_actions_tests : XCTestCase

@end

@implementation yas_ui_layout_actions_tests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)test_update_layout_action {
    ui::layout_guide target;
    auto time = std::chrono::system_clock::now();
    ui::continuous_action::args args{.duration = 1.0, .action = {.begin_time = time}};
    auto action = ui::make_action(
        {.target = target, .begin_value = 0.0f, .end_value = 1.0f, .continuous_action = std::move(args)});

    auto &updatable = action.updatable();

    updatable.update(time);

    XCTAssertEqual(target.value(), 0.0f);

    updatable.update(time + 500ms);

    XCTAssertEqual(target.value(), 0.5f);

    updatable.update(time + 1s);

    XCTAssertEqual(target.value(), 1.0f);
}

- (void)test_make_layout_guide_pairs_from_point_pair {
    ui::layout_guide_point src_point;
    ui::layout_guide_point dst_point;

    auto pairs = ui::make_layout_guide_pairs({.source = src_point, .destination = dst_point});

    XCTAssertEqual(pairs.at(0).source, src_point.x());
    XCTAssertEqual(pairs.at(0).destination, dst_point.x());
    XCTAssertEqual(pairs.at(1).source, src_point.y());
    XCTAssertEqual(pairs.at(1).destination, dst_point.y());
}

- (void)test_make_layout_guide_pairs_from_range_pair {
    ui::layout_guide_range src_range;
    ui::layout_guide_range dst_range;

    auto pairs = ui::make_layout_guide_pairs({.source = src_range, .destination = dst_range});

    XCTAssertEqual(pairs.at(0).source, src_range.min());
    XCTAssertEqual(pairs.at(0).destination, dst_range.min());
    XCTAssertEqual(pairs.at(1).source, src_range.max());
    XCTAssertEqual(pairs.at(1).destination, dst_range.max());
}

- (void)test_make_layout_guide_pairs_from_rect_pair {
    ui::layout_guide_rect src_rect;
    ui::layout_guide_rect dst_rect;

    auto pairs = ui::make_layout_guide_pairs({.source = src_rect, .destination = dst_rect});

    XCTAssertEqual(pairs.at(0).source, src_rect.left());
    XCTAssertEqual(pairs.at(0).destination, dst_rect.left());
    XCTAssertEqual(pairs.at(1).source, src_rect.right());
    XCTAssertEqual(pairs.at(1).destination, dst_rect.right());
    XCTAssertEqual(pairs.at(2).source, src_rect.bottom());
    XCTAssertEqual(pairs.at(2).destination, dst_rect.bottom());
    XCTAssertEqual(pairs.at(3).source, src_rect.top());
    XCTAssertEqual(pairs.at(3).destination, dst_rect.top());
}

@end
