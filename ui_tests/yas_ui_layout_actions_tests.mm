//
//  yas_ui_layout_actions_tests.mm
//

#import <XCTest/XCTest.h>
#import <ui/yas_ui_umbrella.h>

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
    auto const target = layout_value_guide::make_shared();
    auto const time = std::chrono::system_clock::now();
    auto const action =
        make_action({.target = target, .begin_value = 0.0f, .end_value = 1.0f, .duration = 1.0, .begin_time = time});

    action->update(time);

    XCTAssertEqual(target->value(), 0.0f);

    action->update(time + 500ms);

    XCTAssertEqual(target->value(), 0.5f);

    action->update(time + 1s);

    XCTAssertEqual(target->value(), 1.0f);
}

- (void)test_make_layout_guide_pairs_from_point_pair {
    auto const src_point = layout_point_guide::make_shared();
    auto const dst_point = layout_point_guide::make_shared();

    auto const pairs = make_layout_guide_pairs({.source = src_point, .destination = dst_point});

    XCTAssertEqual(pairs.at(0).source, src_point->x());
    XCTAssertEqual(pairs.at(0).destination, dst_point->x());
    XCTAssertEqual(pairs.at(1).source, src_point->y());
    XCTAssertEqual(pairs.at(1).destination, dst_point->y());
}

- (void)test_make_layout_guide_pairs_from_range_pair {
    auto const src_range = layout_range_guide::make_shared();
    auto const dst_range = layout_range_guide::make_shared();

    auto const pairs = make_layout_guide_pairs({.source = src_range, .destination = dst_range});

    XCTAssertEqual(pairs.at(0).source, src_range->min());
    XCTAssertEqual(pairs.at(0).destination, dst_range->min());
    XCTAssertEqual(pairs.at(1).source, src_range->max());
    XCTAssertEqual(pairs.at(1).destination, dst_range->max());
}

- (void)test_make_layout_guide_pairs_from_region_pair {
    auto const src_guide = layout_region_guide::make_shared();
    auto const dst_guide = layout_region_guide::make_shared();

    auto const pairs = make_layout_guide_pairs({.source = src_guide, .destination = dst_guide});

    XCTAssertEqual(pairs.at(0).source, src_guide->left());
    XCTAssertEqual(pairs.at(0).destination, dst_guide->left());
    XCTAssertEqual(pairs.at(1).source, src_guide->right());
    XCTAssertEqual(pairs.at(1).destination, dst_guide->right());
    XCTAssertEqual(pairs.at(2).source, src_guide->bottom());
    XCTAssertEqual(pairs.at(2).destination, dst_guide->bottom());
    XCTAssertEqual(pairs.at(3).source, src_guide->top());
    XCTAssertEqual(pairs.at(3).destination, dst_guide->top());
}

@end
