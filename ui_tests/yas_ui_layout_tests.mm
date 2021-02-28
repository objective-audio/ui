//
//  yas_ui_fixed_layout_tests.mm
//

#import <XCTest/XCTest.h>
#import <ui/ui.h>

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
    auto src_guide = ui::layout_guide::make_shared(0.5f);
    auto dst_guide = ui::layout_guide::make_shared(0.25f);

    auto layout = src_guide->observe([&dst_guide](float const &value) { dst_guide->set_value(value + 8.0f); }, true);

    XCTAssertTrue(layout);

    XCTAssertEqual(src_guide->value(), 0.5f);
    XCTAssertEqual(dst_guide->value(), 8.5f);
}

- (void)test_make_fixed_layout_with_point {
    ui::point distances{.x = 0.5f, .y = 0.25f};
    auto src_guide_point = ui::layout_guide_point::make_shared({.x = 1.0f, .y = 2.0f});
    auto dst_guide_point = ui::layout_guide_point::make_shared({.x = 3.0f, .y = 4.0f});

    auto layout = src_guide_point->observe(
        [&dst_guide_point, distances](ui::point const &value) { dst_guide_point->set_point(value + distances); }, true);

    XCTAssertTrue(layout);

    XCTAssertEqual(src_guide_point->point().x, 1.0f);
    XCTAssertEqual(src_guide_point->point().y, 2.0f);
    XCTAssertEqual(dst_guide_point->point().x, 1.5f);
    XCTAssertEqual(dst_guide_point->point().y, 2.25f);
}

- (void)test_make_fixed_layout_with_rect {
    ui::insets distances{.left = 5.0f, .right = 6.0f, .bottom = 7.0f, .top = 8.0f};
    auto src_guide_rect = ui::layout_guide_rect::make_shared({.origin = {10.0f, 12.0f}, .size = {1.0f, 1.0f}});
    auto dst_guide_rect = ui::layout_guide_rect::make_shared({.origin = {100.0f, 110.0f}, .size = {120.0f, 130.0f}});

    auto layout = src_guide_rect->observe(
        [&dst_guide_rect, distances](ui::region const &region) { dst_guide_rect->set_region(region + distances); },
        true);

    XCTAssertTrue(layout);

    XCTAssertEqual(src_guide_rect->left()->value(), 10.0f);
    XCTAssertEqual(src_guide_rect->right()->value(), 11.0f);
    XCTAssertEqual(src_guide_rect->bottom()->value(), 12.0f);
    XCTAssertEqual(src_guide_rect->top()->value(), 13.0f);
    XCTAssertEqual(dst_guide_rect->left()->value(), 15.0f);
    XCTAssertEqual(dst_guide_rect->right()->value(), 17.0f);
    XCTAssertEqual(dst_guide_rect->bottom()->value(), 19.0f);
    XCTAssertEqual(dst_guide_rect->top()->value(), 21.0f);
}

- (void)test_fixed_layout_value_changed {
    auto src_guide = ui::layout_guide::make_shared(2.0f);
    auto dst_guide = ui::layout_guide::make_shared(-4.0f);

    auto layout = src_guide->observe([&dst_guide](float const &value) { dst_guide->set_value(value + 1.0f); }, true);

    XCTAssertEqual(dst_guide->value(), 3.0f);

    src_guide->set_value(5.0f);

    XCTAssertEqual(dst_guide->value(), 6.0f);
}

#pragma mark -

- (void)test_min_layout {
    auto src_guide_0 = ui::layout_guide::make_shared(1.0f);
    auto src_guide_1 = ui::layout_guide::make_shared(2.0f);
    auto dst_guide = ui::layout_guide::make_shared(-1.0f);

    auto cache0 = std::make_shared<std::optional<float>>();
    auto cache1 = std::make_shared<std::optional<float>>();

    auto set_min = [&dst_guide, cache0, cache1] {
        if (cache0->has_value() && cache1->has_value()) {
            dst_guide->set_value(std::min(**cache0, **cache1));
        }
    };

    auto canceller0 = src_guide_0->observe(
        [cache0, set_min](float const &value) {
            *cache0 = value;
            set_min();
        },
        true);

    auto canceller1 = src_guide_1->observe(
        [cache1, set_min](float const &value) {
            *cache1 = value;
            set_min();
        },
        true);

    XCTAssertEqual(dst_guide->value(), 1.0f);

    src_guide_0->set_value(-1.0f);

    XCTAssertEqual(dst_guide->value(), -1.0f);

    src_guide_0->set_value(5.0f);

    XCTAssertEqual(dst_guide->value(), 2.0f);

    src_guide_1->set_value(1.0f);

    XCTAssertEqual(dst_guide->value(), 1.0f);
}

- (void)test_max_layout {
    auto src_guide_0 = ui::layout_guide::make_shared(1.0f);
    auto src_guide_1 = ui::layout_guide::make_shared(2.0f);
    auto dst_guide = ui::layout_guide::make_shared(3.0f);

    auto cache0 = std::make_shared<std::optional<float>>();
    auto cache1 = std::make_shared<std::optional<float>>();

    auto set_max = [&dst_guide, cache0, cache1] {
        if (cache0->has_value() && cache1->has_value()) {
            dst_guide->set_value(std::max(**cache0, **cache1));
        }
    };

    auto canceller0 = src_guide_0->observe(
        [cache0, set_max](float const &value) {
            *cache0 = value;
            set_max();
        },
        true);

    auto canceller1 = src_guide_1->observe(
        [cache1, set_max](float const &value) {
            *cache1 = value;
            set_max();
        },
        true);

    XCTAssertEqual(dst_guide->value(), 2.0f);

    src_guide_0->set_value(5.0f);

    XCTAssertEqual(dst_guide->value(), 5.0f);

    src_guide_0->set_value(-1.0f);

    XCTAssertEqual(dst_guide->value(), 2.0f);

    src_guide_1->set_value(4.0f);

    XCTAssertEqual(dst_guide->value(), 4.0f);
}

@end
