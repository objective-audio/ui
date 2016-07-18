//
//  yas_ui_collider_tests.mm
//

#import <XCTest/XCTest.h>
#import <sstream>
#import "yas_ui_collider.h"

using namespace yas;

@interface yas_ui_collider_tests : XCTestCase

@end

@implementation yas_ui_collider_tests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)test_create {
    ui::collider collider;

    XCTAssertTrue(collider);
    XCTAssertFalse(collider.shape());

    XCTAssertTrue(collider.renderable());
    XCTAssertTrue(collider.renderable().matrix() == simd::float4x4{matrix_identity_float4x4});
}

- (void)test_create_with_args {
    ui::collider collider{ui::circle_shape{{.center = {1.0f, 2.0f}, .radius = 3.0f}}};

    XCTAssertTrue(collider);
    XCTAssertTrue(collider.shape());

    auto const circle_shape = cast<ui::circle_shape>(collider.shape());
    XCTAssertTrue(circle_shape);
    XCTAssertEqual(circle_shape.center().x, 1.0f);
    XCTAssertEqual(circle_shape.center().y, 2.0f);
    XCTAssertEqual(circle_shape.radius(), 3.0f);
}

- (void)test_create_null {
    ui::collider collider{nullptr};

    XCTAssertFalse(collider);
}

- (void)test_set_variables {
    ui::collider collider;

    XCTAssertFalse(collider.shape());

    collider.set_shape(ui::rect_shape{});

    XCTAssertTrue(collider.shape());
    XCTAssertTrue(cast<ui::rect_shape>(collider.shape()));
    XCTAssertFalse(cast<ui::circle_shape>(collider.shape()));

    collider.set_shape(nullptr);

    XCTAssertFalse(collider.shape());
}

- (void)test_hit_test_none {
    ui::collider collider;

    XCTAssertFalse(collider.hit_test(0.0f));
}

- (void)test_hit_test_anywhere {
    ui::collider collider{ui::anywhere_shape{}};

    XCTAssertTrue(collider.hit_test(0.0f));
    XCTAssertTrue(collider.hit_test(FLT_MAX));
    XCTAssertTrue(collider.hit_test(FLT_MIN));
}

- (void)test_hit_test_rect {
    ui::collider collider{ui::rect_shape{{-0.5f, -0.5f, 1.0f, 1.0f}}};

    XCTAssertTrue(collider.hit_test(0.0f));
    XCTAssertTrue(collider.hit_test(-0.5f));
    XCTAssertTrue(collider.hit_test(0.5f));

    XCTAssertFalse(collider.hit_test({-0.51f, 0.0f}));
    XCTAssertFalse(collider.hit_test({0.51f, 0.0f}));
    XCTAssertFalse(collider.hit_test({0.0f, -0.51f}));
    XCTAssertFalse(collider.hit_test({0.0f, 0.51f}));
}

- (void)test_hit_test_circle {
    ui::collider collider{ui::circle_shape{{.center = 0.0f, .radius = 0.5f}}};

    XCTAssertTrue(collider.hit_test(0.0f));
    XCTAssertTrue(collider.hit_test({-0.5f, 0.0f}));
    XCTAssertTrue(collider.hit_test({0.5f, 0.0f}));
    XCTAssertTrue(collider.hit_test({0.0f, -0.5f}));
    XCTAssertTrue(collider.hit_test({0.0f, 0.5f}));

    XCTAssertFalse(collider.hit_test(-0.4f));
    XCTAssertFalse(collider.hit_test(0.4f));
}

- (void)test_renderable_variables {
    ui::collider collider;

    auto &renderable = collider.renderable();

    simd::float4x4 matrix{simd::float4{1.0f, 2.0f, 3.0f, 4.0f}, simd::float4{5.0f, 6.0f, 7.0f, 8.0f},
                          simd::float4{9.0f, 10.0f, 11.0f, 12.0f}, simd::float4{13.0f, 14.0f, 15.0f, 16.0f}};

    renderable.set_matrix(matrix);

    XCTAssertTrue(renderable.matrix() == matrix);
}

@end
