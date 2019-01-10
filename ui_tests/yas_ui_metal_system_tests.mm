//
//  yas_ui_metal_system_tests.mm
//

#import <XCTest/XCTest.h>
#import <cpp_utils/yas_objc_ptr.h>
#import <ui/yas_ui_metal_system.h>
#import <iostream>

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

    XCTAssertTrue(system);

    ui::testable_metal_system testable = system.testable();

    XCTAssertNotNil(testable.mtlDevice());
    XCTAssertEqual(testable.sample_count(), 4);
}

- (void)test_create_with_sample_count {
    auto device = make_objc_ptr(MTLCreateSystemDefaultDevice());
    if (!device) {
        std::cout << "skip : " << __PRETTY_FUNCTION__ << std::endl;
        return;
    }

    ui::metal_system system{device.object(), 1};

    XCTAssertTrue(system);

    ui::testable_metal_system testable = system.testable();

    XCTAssertNotNil(testable.mtlDevice());
    XCTAssertEqual(testable.sample_count(), 1);
}

- (void)test_create_null {
    ui::metal_system system{nullptr};

    XCTAssertFalse(system);
}

@end
