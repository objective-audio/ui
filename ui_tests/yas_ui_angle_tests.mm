//
//  yas_ui_angle_tests.mm
//

#import <XCTest/XCTest.h>
#import "yas_ui_angle.h"

using namespace yas;

@interface yas_ui_angle_tests : XCTestCase

@end

@implementation yas_ui_angle_tests

- (void)setUp {
    [super setUp];
}

- (void)test_construct {
    ui::angle angle{180.0f};

    XCTAssertEqualWithAccuracy(angle.radians(), M_PI, 0.001f);
    XCTAssertEqualWithAccuracy(angle.degrees, 180.0f, 0.001f);
}

- (void)test_make_radians {
    ui::angle angle = ui::make_radians_angle(M_PI);

    XCTAssertEqualWithAccuracy(angle.radians(), M_PI, 0.001f);
    XCTAssertEqualWithAccuracy(angle.degrees, 180.0f, 0.001f);
}

- (void)test_make_degrees {
    ui::angle angle = ui::make_degrees_angle(180.0f);

    XCTAssertEqualWithAccuracy(angle.radians(), M_PI, 0.001f);
    XCTAssertEqualWithAccuracy(angle.degrees, 180.0f, 0.001f);
}

@end
