//
//  yas_ui_metal_system_tests.mm
//

#import <XCTest/XCTest.h>
#import <cpp-utils/objc_ptr.h>
#import <ui/yas_ui_umbrella.h>
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

    auto const system = metal_system::make_shared(device.object(), nil);

    XCTAssertTrue(system);

    std::shared_ptr<metal_system_for_view> const view_metal_system = system;

    XCTAssertNotNil(view_metal_system->mtlDevice());
    XCTAssertEqual(view_metal_system->sample_count(), 1);
}

- (void)test_create_with_sample_count {
    auto device = objc_ptr_with_move_object(MTLCreateSystemDefaultDevice());
    if (!device) {
        std::cout << "skip : " << __PRETTY_FUNCTION__ << std::endl;
        return;
    }

    auto const system = metal_system::make_shared(device.object(), nil, 1);

    XCTAssertTrue(system);

    std::shared_ptr<metal_system_for_view> const view_metal_system = system;

    XCTAssertNotNil(view_metal_system->mtlDevice());
    XCTAssertEqual(view_metal_system->sample_count(), 1);
}

@end
