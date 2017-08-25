//
//  yas_ui_math_tests.mm
//

#import <XCTest/XCTest.h>
#import "yas_ui_math.h"

using namespace yas;

@interface yas_ui_math_tests : XCTestCase

@end

@implementation yas_ui_math_tests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)test_roundf {
    XCTAssertEqual(roundf(0.6f, 2.0), 0.5f);
    XCTAssertEqual(roundf(0.4f, 2.0), 0.5f);
    XCTAssertEqual(roundf(0.8f, 2.0), 1.0f);
    XCTAssertEqual(roundf(0.2f, 2.0), 0.0f);
}

- (void)test_round {
    XCTAssertEqual(round(0.6, 2.0f), 0.5);
    XCTAssertEqual(round(0.4, 2.0f), 0.5);
    XCTAssertEqual(round(0.8, 2.0f), 1.0);
    XCTAssertEqual(round(0.2, 2.0f), 0.0);
}

- (void)test_ceilf {
    XCTAssertEqual(ceilf(0.2f, 2.0), 0.5f);
    XCTAssertEqual(ceilf(0.4f, 2.0), 0.5f);
    XCTAssertEqual(ceilf(0.6f, 2.0), 1.0f);
    XCTAssertEqual(ceilf(0.8f, 2.0), 1.0f);
}

- (void)test_ceil {
    XCTAssertEqual(ceil(0.2, 2.0), 0.5);
    XCTAssertEqual(ceil(0.4, 2.0), 0.5);
    XCTAssertEqual(ceil(0.6, 2.0), 1.0);
    XCTAssertEqual(ceil(0.8, 2.0), 1.0);
}

- (void)test_distance {
    XCTAssertEqualWithAccuracy(distance({0.0f, 0.0f}, {1.0f, 1.0f}), std::sqrtf(2.0f), 0.001);
    XCTAssertEqualWithAccuracy(distance({0.0f, 0.0f}, {2.0f, 1.0f}),
                               std::sqrtf(std::powf(2.0f - 0.0f, 2.0f) + std::powf(1.0f - 0.0f, 2.0f)), 0.001);
    XCTAssertEqualWithAccuracy(distance({-1.0f, -2.0f}, {2.0f, 1.0f}),
                               std::sqrtf(std::powf(2.0f + 1.0f, 2.0f) + std::powf(1.0f + 2.0f, 2.0f)), 0.001);
}

- (void)test_degrees_from_radians {
    XCTAssertEqualWithAccuracy(degrees_from_radians(0.0f), 0.0f, 0.001);
    XCTAssertEqualWithAccuracy(degrees_from_radians(M_PI), 180.0f, 0.001);
    XCTAssertEqualWithAccuracy(degrees_from_radians(-M_PI), -180.0f, 0.001);
}

- (void)test_radians_from_degrees {
    XCTAssertEqualWithAccuracy(radians_from_degrees(0.0f), 0.0f, 0.001);
    XCTAssertEqualWithAccuracy(radians_from_degrees(180.0f), M_PI, 0.001);
    XCTAssertEqualWithAccuracy(radians_from_degrees(-180.0f), -M_PI, 0.001);
}

@end

