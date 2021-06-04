//
//  yas_ui_fixed_layout_tests.mm
//

#import <XCTest/XCTest.h>
#import <ui/ui.h>

using namespace yas;
using namespace yas::ui;

@interface yas_ui_layout_tests : XCTestCase

@end

@implementation yas_ui_layout_tests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)test_layout_constant_with_value {
    auto const src_guide = layout_guide::make_shared(0.5f);
    auto const dst_guide = layout_guide::make_shared(0.25f);

    auto const canceller = layout(src_guide, dst_guide, [](float const &value) { return value + 8.0f; }).sync();

    XCTAssertEqual(src_guide->value(), 0.5f);
    XCTAssertEqual(dst_guide->value(), 8.5f);

    canceller->cancel();
}

- (void)test_layout_constant_with_point {
    auto const src_guide = layout_guide_point::make_shared({.x = 1.0f, .y = 2.0f});
    auto const dst_guide = layout_guide_point::make_shared({.x = 3.0f, .y = 4.0f});

    auto const canceller = layout(src_guide, dst_guide, [](ui::point const &point) {
                               return point + ui::point{.x = 0.5f, .y = 0.25f};
                           }).sync();

    XCTAssertEqual(src_guide->point().x, 1.0f);
    XCTAssertEqual(src_guide->point().y, 2.0f);
    XCTAssertEqual(dst_guide->point().x, 1.5f);
    XCTAssertEqual(dst_guide->point().y, 2.25f);

    canceller->cancel();
}

- (void)test_layout_constant_with_region {
    auto const src_guide = layout_guide_rect::make_shared({.origin = {10.0f, 12.0f}, .size = {1.0f, 1.0f}});
    auto const dst_guide = layout_guide_rect::make_shared({.origin = {100.0f, 110.0f}, .size = {120.0f, 130.0f}});

    auto const canceller = layout(src_guide, dst_guide, [](ui::region const &region) {
                               return region + insets{.left = 5.0f, .right = 6.0f, .bottom = 7.0f, .top = 8.0f};
                           }).sync();

    XCTAssertEqual(src_guide->left()->value(), 10.0f);
    XCTAssertEqual(src_guide->right()->value(), 11.0f);
    XCTAssertEqual(src_guide->bottom()->value(), 12.0f);
    XCTAssertEqual(src_guide->top()->value(), 13.0f);
    XCTAssertEqual(dst_guide->left()->value(), 15.0f);
    XCTAssertEqual(dst_guide->right()->value(), 17.0f);
    XCTAssertEqual(dst_guide->bottom()->value(), 19.0f);
    XCTAssertEqual(dst_guide->top()->value(), 21.0f);

    canceller->cancel();
}

- (void)test_layout_constant_value_changed {
    auto const src_guide = layout_guide::make_shared(2.0f);
    auto const dst_guide = layout_guide::make_shared(-4.0f);

    auto const canceller = layout(src_guide, dst_guide, [](float const &value) { return value + 1.0f; }).sync();

    XCTAssertEqual(dst_guide->value(), 3.0f);

    src_guide->set_value(5.0f);

    XCTAssertEqual(dst_guide->value(), 6.0f);

    canceller->cancel();
}

#pragma mark -

- (void)test_min_layout {
    auto const src_guide_0 = layout_guide::make_shared(1.0f);
    auto const src_guide_1 = layout_guide::make_shared(2.0f);
    auto const dst_guide = layout_guide::make_shared(-1.0f);

    struct cache {
        std::optional<float> value0;
        std::optional<float> value1;

        std::optional<float> min() {
            if (value0.has_value() && value1.has_value()) {
                return std::min(value0.value(), value1.value());
            } else if (value0.has_value()) {
                return value0.value();
            } else if (value1.has_value()) {
                return value1.value();
            } else {
                return std::nullopt;
            }
        }
    };

    auto const cache = std::make_shared<struct cache>();

    auto canceller0 = layout(src_guide_0, dst_guide, [cache](float const &value) {
                          cache->value0 = value;
                          return *cache->min();
                      }).sync();

    auto canceller1 = layout(src_guide_1, dst_guide, [cache](float const &value) {
                          cache->value1 = value;
                          return *cache->min();
                      }).sync();

    XCTAssertEqual(dst_guide->value(), 1.0f);

    src_guide_0->set_value(-1.0f);

    XCTAssertEqual(dst_guide->value(), -1.0f);

    src_guide_0->set_value(5.0f);

    XCTAssertEqual(dst_guide->value(), 2.0f);

    src_guide_1->set_value(1.0f);

    XCTAssertEqual(dst_guide->value(), 1.0f);
}

@end
