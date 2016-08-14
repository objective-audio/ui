//
//  yas_ui_layout_constraints_tests.mm
//

#import <XCTest/XCTest.h>
#import "yas_ui_layout_constraints.h"

using namespace yas;

@interface yas_ui_layout_constraints_tests : XCTestCase

@end

@implementation yas_ui_layout_constraints_tests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)test_fixed_layout_constraint_value {
    ui::layout_guide src_guide = 2.0f;
    ui::layout_guide dst_guide = -4.0f;

    ui::fixed_layout_constraint constraint{
        {.distance = 1.0f, .source_guide = src_guide, .destination_guide = dst_guide}};

    XCTAssertEqual(dst_guide.value(), 3.0f);

    constraint.set_distance(-4.0f);

    XCTAssertEqual(dst_guide.value(), -2.0f);

    src_guide.set_value(5.0f);

    XCTAssertEqual(dst_guide.value(), 1.0f);
}

@end
