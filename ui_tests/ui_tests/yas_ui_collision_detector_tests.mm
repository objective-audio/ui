//
//  yas_ui_collision_detector_tests.mm
//

#import <XCTest/XCTest.h>
#import "yas_ui_collision_detector.h"

using namespace yas;

@interface yas_ui_collision_detector_tests : XCTestCase

@end

@implementation yas_ui_collision_detector_tests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)test_create {
    ui::collision_detector detector;

    XCTAssertTrue(detector);
    XCTAssertTrue(detector.updatable());
}

- (void)test_create_null {
    ui::collision_detector detector{nullptr};

    XCTAssertFalse(detector);
}

@end
