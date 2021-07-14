//
//  yas_ui_renderer_tests.mm
//

#import <XCTest/XCTest.h>
#import <cpp_utils/yas_objc_ptr.h>
#import <ui/ui.h>
#import <iostream>
#import <sstream>
#import "yas_test_metal_view_controller.h"

using namespace yas;
using namespace yas::ui;

@interface yas_ui_renderer_tests : XCTestCase

@end

@implementation yas_ui_renderer_tests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [[YASTestMetalViewController sharedViewController] set_renderer:nullptr];
    [super tearDown];
}

- (void)test_create {
    auto const view_look = ui::view_look::make_shared();
    auto const renderer = ui::renderer::make_shared(nullptr, nullptr, nullptr, nullptr, nullptr);
    std::shared_ptr<view_renderer_interface> const view_renderer = renderer;

    XCTAssertFalse(renderer->metal_system());

    XCTAssertTrue(view_renderer);

    XCTAssertEqual(renderer->system_type(), ui::system_type::none);
    XCTAssertFalse(renderer->metal_system());
}

- (void)test_const_getter {
    std::shared_ptr<ui::renderer const> renderer =
        ui::renderer::make_shared(nullptr, nullptr, nullptr, nullptr, nullptr);

    XCTAssertFalse(renderer->metal_system());
}

- (void)test_metal_system {
    auto device = objc_ptr_with_move_object(MTLCreateSystemDefaultDevice());
    if (!device) {
        std::cout << "skip : " << __PRETTY_FUNCTION__ << std::endl;
        return;
    }

    auto renderer =
        ui::renderer::make_shared(ui::metal_system::make_shared(device.object()), nullptr, nullptr, nullptr, nullptr);

    XCTAssertEqual(renderer->system_type(), ui::system_type::metal);
    XCTAssertTrue(renderer->metal_system());
}

@end
