//
//  yas_ui_collider_tests.mm
//

#import <XCTest/XCTest.h>
#import <sstream>
#import "yas_ui_collider.h"
#import "yas_ui_renderer.h"

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
    ui::collider collider{ui::shape{{.center = {1.0f, 2.0f}, .radius = 3.0f}}};

    XCTAssertTrue(collider);
    XCTAssertTrue(collider.shape());
    XCTAssertTrue(collider.shape().type_info() == typeid(ui::shape::circle));

    auto const &circle_shape = collider.shape().get<ui::shape::circle>();
    XCTAssertEqual(circle_shape.center.x, 1.0f);
    XCTAssertEqual(circle_shape.center.y, 2.0f);
    XCTAssertEqual(circle_shape.radius, 3.0f);
}

- (void)test_create_null {
    ui::collider collider{nullptr};

    XCTAssertFalse(collider);
}

- (void)test_set_variables {
    ui::collider collider;

    XCTAssertFalse(collider.shape());
    XCTAssertTrue(collider.is_enabled());

    collider.set_shape(ui::shape{ui::rect_shape{}});

    XCTAssertTrue(collider.shape());

    XCTAssertTrue(collider.shape().type_info() == typeid(ui::shape::rect));

    collider.set_shape(nullptr);

    XCTAssertFalse(collider.shape());

    collider.set_enabled(false);

    XCTAssertFalse(collider.is_enabled());
}

- (void)test_hit_test_none {
    ui::collider collider;

    XCTAssertFalse(collider.hit_test({.v = 0.0f}));
}

- (void)test_hit_test_anywhere {
    ui::collider collider{ui::shape{ui::anywhere_shape{}}};

    XCTAssertTrue(collider.hit_test({.v = 0.0f}));
    XCTAssertTrue(collider.hit_test({.v = FLT_MAX}));
    XCTAssertTrue(collider.hit_test({.v = FLT_MIN}));
}

- (void)test_hit_test_rect {
    ui::collider collider{ui::shape{{{.origin = {-0.5f, -0.5f}, .size = {1.0f, 1.0f}}}}};

    XCTAssertTrue(collider.hit_test({.v = 0.0f}));
    XCTAssertTrue(collider.hit_test({.v = -0.5f}));
    XCTAssertTrue(collider.hit_test({.v = 0.5f}));

    XCTAssertFalse(collider.hit_test({-0.51f, 0.0f}));
    XCTAssertFalse(collider.hit_test({0.51f, 0.0f}));
    XCTAssertFalse(collider.hit_test({0.0f, -0.51f}));
    XCTAssertFalse(collider.hit_test({0.0f, 0.51f}));
}

- (void)test_hit_test_circle {
    ui::collider collider{ui::shape{{.center = 0.0f, .radius = 0.5f}}};

    XCTAssertTrue(collider.hit_test({.v = 0.0f}));
    XCTAssertTrue(collider.hit_test({-0.5f, 0.0f}));
    XCTAssertTrue(collider.hit_test({0.5f, 0.0f}));
    XCTAssertTrue(collider.hit_test({0.0f, -0.5f}));
    XCTAssertTrue(collider.hit_test({0.0f, 0.5f}));

    XCTAssertFalse(collider.hit_test({.v = -0.4f}));
    XCTAssertFalse(collider.hit_test({.v = 0.4f}));
}

- (void)test_renderable_variables {
    ui::collider collider;

    auto &renderable = collider.renderable();

    simd::float4x4 matrix{simd::float4{1.0f, 2.0f, 3.0f, 4.0f}, simd::float4{5.0f, 6.0f, 7.0f, 8.0f},
                          simd::float4{9.0f, 10.0f, 11.0f, 12.0f}, simd::float4{13.0f, 14.0f, 15.0f, 16.0f}};

    renderable.set_matrix(matrix);

    XCTAssertTrue(renderable.matrix() == matrix);
}

- (void)test_hit_test_enabled {
    ui::collider collider{ui::shape{ui::anywhere_shape{}}};

    collider.set_enabled(true);

    XCTAssertTrue(collider.hit_test({.v = 0.0f}));

    collider.set_enabled(false);

    XCTAssertFalse(collider.hit_test({.v = 0.0f}));
}

- (void)test_chain_shape {
    ui::collider collider;

    ui::shape received{nullptr};

    auto observer = collider.chain_shape().perform([&received](ui::shape const &shape) { received = shape; }).end();

    collider.set_shape(ui::shape{ui::anywhere_shape{}});

    XCTAssertTrue(received);
    XCTAssertTrue(received.type_info() == typeid(ui::shape::anywhere));
}

- (void)test_chain_enabled {
    ui::collider collider;

    bool received = true;

    auto observer = collider.chain_enabled().perform([&received](bool const &enabled) { received = enabled; }).end();

    collider.set_enabled(false);

    XCTAssertFalse(received);
}

- (void)test_shape_receiver {
    ui::collider collider;

    chaining::notifier<ui::shape> sender;
    auto observer = sender.chain().receive(collider.shape_receiver()).end();

    XCTAssertFalse(collider.shape());

    sender.notify(ui::shape{ui::circle_shape{}});

    XCTAssertTrue(collider.shape());
    XCTAssertTrue(collider.shape().type_info() == typeid(ui::shape::circle));
}

- (void)test_enabled_receiver {
    ui::collider collider;

    chaining::notifier<bool> sender;
    auto observer = sender.chain().receive(collider.enabled_receiver()).end();

    XCTAssertTrue(collider.is_enabled());

    sender.notify(false);

    XCTAssertFalse(collider.is_enabled());
}

@end
