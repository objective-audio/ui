//
//  yas_ui_metal_system_tests.mm
//

#import <XCTest/XCTest.h>
#import <iostream>
#import "yas_objc_ptr.h"
#import "yas_ui_metal_system.h"

using namespace yas;

@interface yas_ui_metal_system_tests : XCTestCase

@end

@implementation yas_ui_metal_system_tests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)test_create {
    auto device = make_objc_ptr(MTLCreateSystemDefaultDevice());
    if (!device) {
        std::cout << "skip : " << __PRETTY_FUNCTION__ << std::endl;
        return;
    }

    ui::metal_system system{device.object()};

    XCTAssertEqualObjects(system.device(), device.object());
    XCTAssertEqual(system.sample_count(), 4);
}

- (void)test_create_null {
    ui::metal_system system{nullptr};

    XCTAssertFalse(system);
}

@end
