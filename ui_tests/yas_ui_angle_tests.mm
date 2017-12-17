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

- (void)test_equal {
    ui::angle angle_one_a{1.0f};
    ui::angle angle_one_b{1.0f};
    ui::angle angle_two{2.0f};

    XCTAssertTrue(angle_one_a == angle_one_b);
    XCTAssertFalse(angle_one_a == angle_two);
}

- (void)test_not_equal {
    ui::angle angle_one_a{1.0f};
    ui::angle angle_one_b{1.0f};
    ui::angle angle_two{2.0f};

    XCTAssertFalse(angle_one_a != angle_one_b);
    XCTAssertTrue(angle_one_a != angle_two);
}

- (void)test_plus {
    ui::angle angle_a{1.0f};
    ui::angle angle_b{2.0f};
    ui::angle angle_c = angle_a + angle_b;

    XCTAssertEqualWithAccuracy(angle_c.degrees, 3.0f, 0.001f);
}

- (void)test_minus {
    ui::angle angle_a{3.0f};
    ui::angle angle_b{1.0f};
    ui::angle angle_c = angle_a - angle_b;

    XCTAssertEqualWithAccuracy(angle_c.degrees, 2.0f, 0.001f);
}

- (void)test_plus_equal {
    ui::angle angle{1.0f};
    angle += ui::angle{2.0f};

    XCTAssertEqualWithAccuracy(angle.degrees, 3.0f, 0.001f);
}

- (void)test_minus_equal {
    ui::angle angle{3.0f};
    angle -= ui::angle{1.0f};

    XCTAssertEqualWithAccuracy(angle.degrees, 2.0f, 0.001f);
}

- (void)test_zero {
    auto const zero_angle = ui::angle::zero();

    XCTAssertEqual(zero_angle.degrees, 0.0f);
    XCTAssertEqual(zero_angle.radians(), 0.0f);
}

@end
