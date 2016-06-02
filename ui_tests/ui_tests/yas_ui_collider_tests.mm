//
//  yas_ui_collider_tests.mm
//

#import <XCTest/XCTest.h>
#import <iostream>
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
    XCTAssertEqual(collider.shape(), ui::collider_shape::none);
    XCTAssertEqual(collider.center().x, 0.0f);
    XCTAssertEqual(collider.center().y, 0.0f);
    XCTAssertEqual(collider.radius(), 0.5f);

    XCTAssertTrue(collider.renderable());
    XCTAssertTrue(collider.renderable().matrix() == simd::float4x4{matrix_identity_float4x4});
}

- (void)test_create_with_args {
    ui::collider_args args{.shape = ui::collider_shape::circle, .center = {1.0f, 2.0f}, .radius = 3.0f};

    ui::collider collider{std::move(args)};

    XCTAssertTrue(collider);
    XCTAssertEqual(collider.shape(), ui::collider_shape::circle);
    XCTAssertEqual(collider.center().x, 1.0f);
    XCTAssertEqual(collider.center().y, 2.0f);
    XCTAssertEqual(collider.radius(), 3.0f);
}

- (void)test_create_null {
    ui::collider collider{nullptr};

    XCTAssertFalse(collider);
}

- (void)test_set_variables {
    ui::collider collider;

    collider.set_shape(ui::collider_shape::square);

    XCTAssertEqual(collider.shape(), ui::collider_shape::square);

    collider.set_center({11.0f, 12.0f});

    XCTAssertEqual(collider.center().x, 11.0f);
    XCTAssertEqual(collider.center().y, 12.0f);

    collider.set_radius(20.0f);

    XCTAssertEqual(collider.radius(), 20.0f);
}

- (void)test_hit_test_none {
    ui::collider collider{{.shape = ui::collider_shape::none, .center = 0.0f, .radius = 0.5f}};

    XCTAssertFalse(collider.hit_test(0.0f));
}

- (void)test_hit_test_anywhere {
    ui::collider collider{{.shape = ui::collider_shape::anywhere, .center = 0.0f, .radius = 0.5f}};

    XCTAssertTrue(collider.hit_test(0.0f));
    XCTAssertTrue(collider.hit_test(FLT_MAX));
    XCTAssertTrue(collider.hit_test(FLT_MIN));
}

- (void)test_hit_test_square {
    ui::collider collider{{.shape = ui::collider_shape::square, .center = 0.0f, .radius = 0.5f}};

    XCTAssertTrue(collider.hit_test(0.0f));
    XCTAssertTrue(collider.hit_test(-0.5f));
    XCTAssertTrue(collider.hit_test(0.5f));

    XCTAssertFalse(collider.hit_test({-0.51f, 0.0f}));
    XCTAssertFalse(collider.hit_test({0.51f, 0.0f}));
    XCTAssertFalse(collider.hit_test({0.0f, -0.51f}));
    XCTAssertFalse(collider.hit_test({0.0f, 0.51f}));
}

- (void)test_hit_test_circle {
    ui::collider collider{{.shape = ui::collider_shape::circle, .center = 0.0f, .radius = 0.5f}};

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

- (void)test_collider_shape_to_string {
    XCTAssertEqual(to_string(ui::collider_shape::none), "none");
    XCTAssertEqual(to_string(ui::collider_shape::anywhere), "anywhere");
    XCTAssertEqual(to_string(ui::collider_shape::circle), "circle");
    XCTAssertEqual(to_string(ui::collider_shape::square), "square");
}

- (void)test_collider_shape_ostream {
    std::cout << ui::collider_shape::circle << std::endl;
}

@end
