//
//  yas_ui_metal_system_tests.mm
//

#import <XCTest/XCTest.h>
#import <cpp_utils/yas_objc_ptr.h>
#import <ui/ui.h>
#import <iostream>

using namespace yas;
using namespace yas::ui;

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
    auto device = objc_ptr_with_move_object(MTLCreateSystemDefaultDevice());
    if (!device) {
        std::cout << "skip : " << __PRETTY_FUNCTION__ << std::endl;
        return;
    }

    auto system = metal_system::make_shared(device.object());

    XCTAssertTrue(system);
    XCTAssertNotNil(system->mtlDevice());
    XCTAssertEqual(system->sample_count(), 4);
}

- (void)test_create_with_sample_count {
    auto device = objc_ptr_with_move_object(MTLCreateSystemDefaultDevice());
    if (!device) {
        std::cout << "skip : " << __PRETTY_FUNCTION__ << std::endl;
        return;
    }

    auto system = metal_system::make_shared(device.object(), 1);

    XCTAssertTrue(system);
    XCTAssertNotNil(system->mtlDevice());
    XCTAssertEqual(system->sample_count(), 1);
}

@end
