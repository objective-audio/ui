//
//  yas_ui_angle_tests.mm
//

#import <XCTest/XCTest.h>
#import <ui/yas_ui_umbrella.h>

using namespace yas;
using namespace yas::ui;

@interface yas_ui_angle_tests : XCTestCase

@end

@implementation yas_ui_angle_tests

- (void)setUp {
    [super setUp];
}

- (void)test_construct {
    angle angle{180.0f};

    XCTAssertEqualWithAccuracy(angle.radians(), M_PI, 0.001f);
    XCTAssertEqualWithAccuracy(angle.degrees, 180.0f, 0.001f);
}

- (void)test_make_radians {
    angle angle = angle::make_radians(M_PI);

    XCTAssertEqualWithAccuracy(angle.radians(), M_PI, 0.001f);
    XCTAssertEqualWithAccuracy(angle.degrees, 180.0f, 0.001f);
}

- (void)test_make_degrees {
    angle angle = angle::make_degrees(180.0f);

    XCTAssertEqualWithAccuracy(angle.radians(), M_PI, 0.001f);
    XCTAssertEqualWithAccuracy(angle.degrees, 180.0f, 0.001f);
}

- (void)test_equal {
    angle angle_one_a{1.0f};
    angle angle_one_b{1.0f};
    angle angle_two{2.0f};

    XCTAssertTrue(angle_one_a == angle_one_b);
    XCTAssertFalse(angle_one_a == angle_two);
}

- (void)test_not_equal {
    angle angle_one_a{1.0f};
    angle angle_one_b{1.0f};
    angle angle_two{2.0f};

    XCTAssertFalse(angle_one_a != angle_one_b);
    XCTAssertTrue(angle_one_a != angle_two);
}

- (void)test_plus {
    angle angle_a{1.0f};
    angle angle_b{2.0f};
    angle angle_c = angle_a + angle_b;

    XCTAssertEqualWithAccuracy(angle_c.degrees, 3.0f, 0.001f);
}

- (void)test_minus {
    angle angle_a{3.0f};
    angle angle_b{1.0f};
    angle angle_c = angle_a - angle_b;

    XCTAssertEqualWithAccuracy(angle_c.degrees, 2.0f, 0.001f);
}

- (void)test_multi {
    angle angle = ui::angle{2.0f} * 3.0f;

    XCTAssertEqualWithAccuracy(angle.degrees, 6.0f, 0.001f);
}

- (void)test_divide {
    angle angle = ui::angle{6.0f} / 3.0f;

    XCTAssertEqualWithAccuracy(angle.degrees, 2.0f, 0.001f);
}

- (void)test_plus_equal {
    angle angle{1.0f};
    angle += ui::angle{2.0f};

    XCTAssertEqualWithAccuracy(angle.degrees, 3.0f, 0.001f);
}

- (void)test_minus_equal {
    angle angle{3.0f};
    angle -= ui::angle{1.0f};

    XCTAssertEqualWithAccuracy(angle.degrees, 2.0f, 0.001f);
}

- (void)test_multi_equal {
    angle angle{2.0f};
    angle *= 3.0f;

    XCTAssertEqualWithAccuracy(angle.degrees, 6.0f, 0.001f);
}

- (void)test_divide_equal {
    angle angle{6.0f};
    angle /= 3.0f;

    XCTAssertEqualWithAccuracy(angle.degrees, 2.0f, 0.001f);
}

- (void)test_unary_minus {
    angle angle{1.0f};
    XCTAssertEqualWithAccuracy((-angle).degrees, -1.0f, 0.001f);
}

- (void)test_shortest_from {
    XCTAssertEqualWithAccuracy(angle{360.0f}.shortest_from({0.0f}).degrees, 0.0f, 0.001f);
    XCTAssertEqualWithAccuracy(angle{450.0f}.shortest_from({0.0f}).degrees, 90.0f, 0.001f);
    XCTAssertEqualWithAccuracy(angle{540.0f}.shortest_from({0.0f}).degrees, 180.0f, 0.001f);
    XCTAssertEqualWithAccuracy(angle{630.0f}.shortest_from({0.0f}).degrees, -90.0f, 0.001f);
    XCTAssertEqualWithAccuracy(angle{720.0f}.shortest_from({0.0f}).degrees, 0.0f, 0.001f);

    XCTAssertEqualWithAccuracy(angle{179.0f}.shortest_from({0.0f}).degrees, 179.0f, 0.001f);
    XCTAssertEqualWithAccuracy(angle{180.0f}.shortest_from({0.0f}).degrees, 180.0f, 0.001f);
    XCTAssertEqualWithAccuracy(angle{181.0f}.shortest_from({0.0f}).degrees, -179.0f, 0.001f);
    XCTAssertEqualWithAccuracy(angle{269.0f}.shortest_from({90.0f}).degrees, 269.0f, 0.001f);
    XCTAssertEqualWithAccuracy(angle{270.0f}.shortest_from({90.0f}).degrees, 270.0f, 0.001f);
    XCTAssertEqualWithAccuracy(angle{271.0f}.shortest_from({90.0f}).degrees, -89.0f, 0.001f);
    XCTAssertEqualWithAccuracy(angle{89.0f}.shortest_from({-90.0f}).degrees, 89.0f, 0.001f);
    XCTAssertEqualWithAccuracy(angle{90.0f}.shortest_from({-90.0f}).degrees, 90.0f, 0.001f);
    XCTAssertEqualWithAccuracy(angle{91.0f}.shortest_from({-90.0f}).degrees, -269.0f, 0.001f);

    XCTAssertEqualWithAccuracy(angle{-360.0f}.shortest_from({0.0f}).degrees, 0.0f, 0.001f);
    XCTAssertEqualWithAccuracy(angle{-450.0f}.shortest_from({0.0f}).degrees, -90.0f, 0.001f);
    XCTAssertEqualWithAccuracy(angle{-540.0f}.shortest_from({0.0f}).degrees, -180.0f, 0.001f);
    XCTAssertEqualWithAccuracy(angle{-630.0f}.shortest_from({0.0f}).degrees, 90.0f, 0.001f);
    XCTAssertEqualWithAccuracy(angle{-720.0f}.shortest_from({0.0f}).degrees, 0.0f, 0.001f);

    XCTAssertEqualWithAccuracy(angle{-179.0f}.shortest_from({0.0f}).degrees, -179.0f, 0.001f);
    XCTAssertEqualWithAccuracy(angle{-180.0f}.shortest_from({0.0f}).degrees, -180.0f, 0.001f);
    XCTAssertEqualWithAccuracy(angle{-181.0f}.shortest_from({0.0f}).degrees, 179.0f, 0.001f);
    XCTAssertEqualWithAccuracy(angle{-269.0f}.shortest_from({-90.0f}).degrees, -269.0f, 0.001f);
    XCTAssertEqualWithAccuracy(angle{-270.0f}.shortest_from({-90.0f}).degrees, -270.0f, 0.001f);
    XCTAssertEqualWithAccuracy(angle{-271.0f}.shortest_from({-90.0f}).degrees, 89.0f, 0.001f);
    XCTAssertEqualWithAccuracy(angle{-89.0f}.shortest_from({90.0f}).degrees, -89.0f, 0.001f);
    XCTAssertEqualWithAccuracy(angle{-90.0f}.shortest_from({90.0f}).degrees, -90.0f, 0.001f);
    XCTAssertEqualWithAccuracy(angle{-91.0f}.shortest_from({90.0f}).degrees, 269.0f, 0.001f);
}

- (void)test_shortest_to {
    XCTAssertEqualWithAccuracy(angle{0.0f}.shortest_to({360.0f}).degrees, 0.0f, 0.001f);
    XCTAssertEqualWithAccuracy(angle{0.0f}.shortest_to({450.0f}).degrees, 90.0f, 0.001f);
    XCTAssertEqualWithAccuracy(angle{0.0f}.shortest_to({540.0f}).degrees, 180.0f, 0.001f);
    XCTAssertEqualWithAccuracy(angle{0.0f}.shortest_to({630.0f}).degrees, -90.0f, 0.001f);
    XCTAssertEqualWithAccuracy(angle{0.0f}.shortest_to({720.0f}).degrees, 0.0f, 0.001f);

    XCTAssertEqualWithAccuracy(angle{0.0f}.shortest_to({179.0f}).degrees, 179.0f, 0.001f);
    XCTAssertEqualWithAccuracy(angle{0.0f}.shortest_to({180.0f}).degrees, 180.0f, 0.001f);
    XCTAssertEqualWithAccuracy(angle{0.0f}.shortest_to({181.0f}).degrees, -179.0f, 0.001f);
    XCTAssertEqualWithAccuracy(angle{90.0f}.shortest_to({269.0f}).degrees, 269.0f, 0.001f);
    XCTAssertEqualWithAccuracy(angle{90.0f}.shortest_to({270.0f}).degrees, 270.0f, 0.001f);
    XCTAssertEqualWithAccuracy(angle{90.0f}.shortest_to({271.0f}).degrees, -89.0f, 0.001f);
    XCTAssertEqualWithAccuracy(angle{-90.0f}.shortest_to({89.0f}).degrees, 89.0f, 0.001f);
    XCTAssertEqualWithAccuracy(angle{-90.0f}.shortest_to({90.0f}).degrees, 90.0f, 0.001f);
    XCTAssertEqualWithAccuracy(angle{-90.0f}.shortest_to({91.0f}).degrees, -269.0f, 0.001f);

    XCTAssertEqualWithAccuracy(angle{0.0f}.shortest_to({-360.0f}).degrees, 0.0f, 0.001f);
    XCTAssertEqualWithAccuracy(angle{0.0f}.shortest_to({-450.0f}).degrees, -90.0f, 0.001f);
    XCTAssertEqualWithAccuracy(angle{0.0f}.shortest_to({-540.0f}).degrees, -180.0f, 0.001f);
    XCTAssertEqualWithAccuracy(angle{0.0f}.shortest_to({-630.0f}).degrees, 90.0f, 0.001f);
    XCTAssertEqualWithAccuracy(angle{0.0f}.shortest_to({-720.0f}).degrees, 0.0f, 0.001f);

    XCTAssertEqualWithAccuracy(angle{0.0f}.shortest_to({-179.0f}).degrees, -179.0f, 0.001f);
    XCTAssertEqualWithAccuracy(angle{0.0f}.shortest_to({-180.0f}).degrees, -180.0f, 0.001f);
    XCTAssertEqualWithAccuracy(angle{0.0f}.shortest_to({-181.0f}).degrees, 179.0f, 0.001f);
    XCTAssertEqualWithAccuracy(angle{-90.0f}.shortest_to({-269.0f}).degrees, -269.0f, 0.001f);
    XCTAssertEqualWithAccuracy(angle{-90.0f}.shortest_to({-270.0f}).degrees, -270.0f, 0.001f);
    XCTAssertEqualWithAccuracy(angle{-90.0f}.shortest_to({-271.0f}).degrees, 89.0f, 0.001f);
    XCTAssertEqualWithAccuracy(angle{90.0f}.shortest_to({-89.0f}).degrees, -89.0f, 0.001f);
    XCTAssertEqualWithAccuracy(angle{90.0f}.shortest_to({-90.0f}).degrees, -90.0f, 0.001f);
    XCTAssertEqualWithAccuracy(angle{90.0f}.shortest_to({-91.0f}).degrees, 269.0f, 0.001f);
}

- (void)test_zero {
    auto const zero_angle = angle::zero();

    XCTAssertEqual(zero_angle.degrees, 0.0f);
    XCTAssertEqual(zero_angle.radians(), 0.0f);
}

@end
