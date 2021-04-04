//
//  yas_ui_collider_tests.mm
//

#import <XCTest/XCTest.h>
#import <ui/ui.h>
#import <sstream>

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
    auto collider = ui::collider::make_shared();

    XCTAssertTrue(collider);
    XCTAssertFalse(collider->shape());

    auto const renderable = ui::renderable_collider::cast(collider);
    XCTAssertTrue(renderable);
    XCTAssertTrue(renderable->matrix() == simd::float4x4{matrix_identity_float4x4});
}

- (void)test_set_variables {
    auto collider = ui::collider::make_shared();

    XCTAssertFalse(collider->shape());
    XCTAssertTrue(collider->is_enabled());

    collider->set_shape(ui::shape::make_shared(ui::rect_shape{}));

    XCTAssertTrue(collider->shape());

    XCTAssertTrue(collider->shape()->type_info() == typeid(ui::shape::rect));

    collider->set_shape(nullptr);

    XCTAssertFalse(collider->shape());

    collider->set_enabled(false);

    XCTAssertFalse(collider->is_enabled());
}

- (void)test_hit_test_none {
    auto collider = ui::collider::make_shared();

    XCTAssertFalse(collider->hit_test({.v = 0.0f}));
}

- (void)test_hit_test_anywhere {
    auto collider = ui::collider::make_shared(ui::shape::make_shared(ui::anywhere_shape{}));

    XCTAssertTrue(collider->hit_test({.v = 0.0f}));
    XCTAssertTrue(collider->hit_test({.v = FLT_MAX}));
    XCTAssertTrue(collider->hit_test({.v = FLT_MIN}));
}

- (void)test_hit_test_rect {
    auto collider =
        ui::collider::make_shared(ui::shape::make_shared({{.origin = {-0.5f, -0.5f}, .size = {1.0f, 1.0f}}}));

    XCTAssertTrue(collider->hit_test({.v = 0.0f}));
    XCTAssertTrue(collider->hit_test({.v = -0.5f}));
    XCTAssertTrue(collider->hit_test({.v = 0.49f}));

    XCTAssertFalse(collider->hit_test({-0.51f, 0.0f}));
    XCTAssertFalse(collider->hit_test({0.51f, 0.0f}));
    XCTAssertFalse(collider->hit_test({0.0f, -0.51f}));
    XCTAssertFalse(collider->hit_test({0.0f, 0.51f}));
}

- (void)test_hit_test_circle {
    auto collider = ui::collider::make_shared(ui::shape::make_shared({.center = 0.0f, .radius = 0.5f}));

    XCTAssertTrue(collider->hit_test({.v = 0.0f}));
    XCTAssertTrue(collider->hit_test({-0.49f, 0.0f}));
    XCTAssertTrue(collider->hit_test({0.49f, 0.0f}));
    XCTAssertTrue(collider->hit_test({0.0f, -0.49f}));
    XCTAssertTrue(collider->hit_test({0.0f, 0.49f}));

    XCTAssertFalse(collider->hit_test({.v = -0.4f}));
    XCTAssertFalse(collider->hit_test({.v = 0.4f}));
}

- (void)test_renderable_variables {
    auto collider = ui::collider::make_shared();

    auto const renderable = ui::renderable_collider::cast(collider);

    simd::float4x4 matrix{simd::float4{1.0f, 2.0f, 3.0f, 4.0f}, simd::float4{5.0f, 6.0f, 7.0f, 8.0f},
                          simd::float4{9.0f, 10.0f, 11.0f, 12.0f}, simd::float4{13.0f, 14.0f, 15.0f, 16.0f}};

    renderable->set_matrix(matrix);

    XCTAssertTrue(renderable->matrix() == matrix);
}

- (void)test_hit_test_enabled {
    auto collider = ui::collider::make_shared(ui::shape::make_shared(ui::anywhere_shape{}));

    collider->set_enabled(true);

    XCTAssertTrue(collider->hit_test({.v = 0.0f}));

    collider->set_enabled(false);

    XCTAssertFalse(collider->hit_test({.v = 0.0f}));
}

- (void)test_chain_shape {
    auto collider = ui::collider::make_shared();

    ui::shape_ptr received{nullptr};

    auto observer = collider->observe_shape([&received](ui::shape_ptr const &shape) { received = shape; }).end();

    collider->set_shape(ui::shape::make_shared(ui::anywhere_shape{}));

    XCTAssertTrue(received);
    XCTAssertTrue(received->type_info() == typeid(ui::shape::anywhere));
}

- (void)test_chain_enabled {
    auto collider = ui::collider::make_shared();

    bool received = true;

    auto observer = collider->observe_enabled([&received](bool const &enabled) { received = enabled; }).end();

    collider->set_enabled(false);

    XCTAssertFalse(received);
}

@end
