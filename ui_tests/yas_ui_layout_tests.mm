//
//  yas_ui_fixed_layout_tests.mm
//

#import <XCTest/XCTest.h>
#import <chaining/yas_chaining_utils.h>
#import <ui/yas_ui_layout_guide.h>

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

    auto layout = src_guide->chain().to(chaining::add(8.0f)).send_to(dst_guide).sync();

    XCTAssertTrue(layout);

    XCTAssertEqual(src_guide->value(), 0.5f);
    XCTAssertEqual(dst_guide->value(), 8.5f);
}

- (void)test_make_fixed_layout_with_point {
    ui::point distances{.x = 0.5f, .y = 0.25f};
    auto src_guide_point = ui::layout_guide_point::make_shared({.x = 1.0f, .y = 2.0f});
    auto dst_guide_point = ui::layout_guide_point::make_shared({.x = 3.0f, .y = 4.0f});

    auto layout = src_guide_point->chain().to(chaining::add(distances)).send_to(dst_guide_point).sync();

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

    auto layout = src_guide_rect->chain().to(chaining::add<ui::region>(distances)).send_to(dst_guide_rect).sync();

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

    auto layout = src_guide->chain().to(chaining::add(1.0f)).send_to(dst_guide).sync();

    XCTAssertEqual(dst_guide->value(), 3.0f);

    src_guide->set_value(5.0f);

    XCTAssertEqual(dst_guide->value(), 6.0f);
}

#pragma mark -

- (void)test_min_layout {
    auto src_guide_0 = ui::layout_guide::make_shared(1.0f);
    auto src_guide_1 = ui::layout_guide::make_shared(2.0f);
    auto dst_guide = ui::layout_guide::make_shared(-1.0f);

    auto layout =
        src_guide_0->chain().combine(src_guide_1->chain()).to(chaining::min<float>()).send_to(dst_guide).sync();

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

    auto layout =
        src_guide_0->chain().combine(src_guide_1->chain()).to(chaining::max<float>()).send_to(dst_guide).sync();

    XCTAssertEqual(dst_guide->value(), 2.0f);

    src_guide_0->set_value(5.0f);

    XCTAssertEqual(dst_guide->value(), 5.0f);

    src_guide_0->set_value(-1.0f);

    XCTAssertEqual(dst_guide->value(), 2.0f);

    src_guide_1->set_value(4.0f);

    XCTAssertEqual(dst_guide->value(), 4.0f);
}

@end
