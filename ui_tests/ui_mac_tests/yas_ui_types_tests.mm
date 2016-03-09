//
//  yas_ui_types_tests.mm
//

#import <XCTest/XCTest.h>
#import "yas_ui_types.h"

using namespace yas;

@interface yas_ui_types_tests : XCTestCase

@end

@implementation yas_ui_types_tests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)test_to_mtl_size {
    ui::uint_size size{.width = 3, .height = 17};

    auto mtl_size = to_mtl_size(size);

    XCTAssertEqual(mtl_size.width, size.width);
    XCTAssertEqual(mtl_size.height, size.height);
    XCTAssertEqual(mtl_size.depth, 1);
}

@end
