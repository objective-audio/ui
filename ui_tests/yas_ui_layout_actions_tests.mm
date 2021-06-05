//
//  yas_ui_layout_actions_tests.mm
//

#import <XCTest/XCTest.h>
#import <ui/ui.h>

using namespace yas;
using namespace yas::ui;
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
    auto target = layout_guide_value::make_shared();
    auto time = std::chrono::system_clock::now();
    auto action =
        make_action({.target = target, .begin_value = 0.0f, .end_value = 1.0f, .duration = 1.0, .begin_time = time});

    action->update(time);

    XCTAssertEqual(target->value(), 0.0f);

    action->update(time + 500ms);

    XCTAssertEqual(target->value(), 0.5f);

    action->update(time + 1s);

    XCTAssertEqual(target->value(), 1.0f);
}

- (void)test_make_layout_guide_pairs_from_point_pair {
    auto src_point = layout_guide_point::make_shared();
    auto dst_point = layout_guide_point::make_shared();

    auto pairs = make_layout_guide_pairs({.source = src_point, .destination = dst_point});

    XCTAssertEqual(pairs.at(0).source, src_point->x());
    XCTAssertEqual(pairs.at(0).destination, dst_point->x());
    XCTAssertEqual(pairs.at(1).source, src_point->y());
    XCTAssertEqual(pairs.at(1).destination, dst_point->y());
}

- (void)test_make_layout_guide_pairs_from_range_pair {
    auto src_range = layout_guide_range::make_shared();
    auto dst_range = layout_guide_range::make_shared();

    auto pairs = make_layout_guide_pairs({.source = src_range, .destination = dst_range});

    XCTAssertEqual(pairs.at(0).source, src_range->min());
    XCTAssertEqual(pairs.at(0).destination, dst_range->min());
    XCTAssertEqual(pairs.at(1).source, src_range->max());
    XCTAssertEqual(pairs.at(1).destination, dst_range->max());
}

- (void)test_make_layout_guide_pairs_from_rect_pair {
    auto src_rect = layout_guide_rect::make_shared();
    auto dst_rect = layout_guide_rect::make_shared();

    auto pairs = make_layout_guide_pairs({.source = src_rect, .destination = dst_rect});

    XCTAssertEqual(pairs.at(0).source, src_rect->left());
    XCTAssertEqual(pairs.at(0).destination, dst_rect->left());
    XCTAssertEqual(pairs.at(1).source, src_rect->right());
    XCTAssertEqual(pairs.at(1).destination, dst_rect->right());
    XCTAssertEqual(pairs.at(2).source, src_rect->bottom());
    XCTAssertEqual(pairs.at(2).destination, dst_rect->bottom());
    XCTAssertEqual(pairs.at(3).source, src_rect->top());
    XCTAssertEqual(pairs.at(3).destination, dst_rect->top());
}

@end
