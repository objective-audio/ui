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
    [super tearDown];
}

- (void)test_create {
    auto const view_look = ui::view_look::make_shared();
    auto const renderer = ui::renderer::make_shared(nullptr, nullptr, nullptr, nullptr, nullptr);
    std::shared_ptr<view_renderer_interface> const view_renderer = renderer;

    XCTAssertTrue(view_renderer);
}

@end
