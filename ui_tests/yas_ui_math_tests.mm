//
//  yas_ui_math_tests.mm
//

#import <XCTest/XCTest.h>
#import <ui/yas_ui_umbrella.h>

using namespace yas;
using namespace yas::ui;

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

@end
