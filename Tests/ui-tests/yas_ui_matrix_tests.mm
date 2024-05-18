//
//  yas_ui_matrix_tests.mm
//

#import <XCTest/XCTest.h>
#import <cpp-utils/each_index.h>
#import <ui/yas_ui_umbrella.h>
#import <iostream>

using namespace simd;
using namespace yas;
using namespace yas::ui;

@interface yas_ui_matrix_tests : XCTestCase

@end

@implementation yas_ui_matrix_tests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)test_scale {
    auto m1 = matrix::scale(2.0, 4.0);

    float4x4 m2(float4{2.0f, 0.0f, 0.0f, 0.0f}, float4{0.0f, 4.0f, 0.0f, 0.0f}, float4{0.0f, 0.0f, 1.0f, 0.0f},
                float4{0.0f, 0.0f, 0.0f, 1.0f});

    XCTAssertTrue(m1 == m2);

    auto v = m1 * float4{1.0f, 2.0f, 0.0f, 1.0f};

    XCTAssertEqualWithAccuracy(v.x, 2.0f, 0.001f);
    XCTAssertEqualWithAccuracy(v.y, 8.0f, 0.001f);
}

- (void)test_translate {
    auto m1 = matrix::translation(3.0f, -1.0);

    float4x4 m2(float4{1.0f, 0.0f, 0.0f, 0.0f}, float4{0.0f, 1.0f, 0.0f, 0.0f}, float4{0.0f, 0.0f, 1.0f, 0.0f},
                float4{3.0f, -1.0f, 0.0f, 1.0f});

    XCTAssertTrue(m1 == m2);

    auto v = m1 * float4{1.0f, 0.0f, 0.0f, 1.0f};

    XCTAssertEqualWithAccuracy(v.x, 4.0f, 0.001f);
    XCTAssertEqualWithAccuracy(v.y, -1.0f, 0.001f);
}

- (void)test_rotation {
    auto v = matrix::rotation(90.0f) * float4{1.0f, 0.0f, 0.0f, 1.0f};
    XCTAssertEqualWithAccuracy(v.x, 0.0f, 0.001f);
    XCTAssertEqualWithAccuracy(v.y, 1.0f, 0.001f);
}

- (void)test_ortho {
    auto m = matrix::ortho(0.0f, 100.0f, -20.0f, 20.0f, -1.0f, 1.0f);

    auto v = m * float4{0.0f, 0.0f, 0.0f, 1.0f};

    XCTAssertEqualWithAccuracy(v.x, -1.0f, 0.001f);
    XCTAssertEqualWithAccuracy(v.y, 0.0f, 0.001f);

    v = m * float4{100.0f, 20.0f, 0.0f, 1.0f};

    XCTAssertEqualWithAccuracy(v.x, 1.0f, 0.001f);
    XCTAssertEqualWithAccuracy(v.y, 1.0f, 0.001f);
}

@end
