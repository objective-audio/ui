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
    auto const renderer = ui::renderer::make_shared(nullptr, view_look, nullptr, nullptr);
    std::shared_ptr<view_renderer_interface> const view_renderer = renderer;

    XCTAssertFalse(renderer->metal_system());

    XCTAssertTrue(renderer->root_node());

    XCTAssertEqual(view_look->view_size(), (ui::uint_size{0, 0}));
    XCTAssertEqual(view_look->drawable_size(), (ui::uint_size{0, 0}));
    XCTAssertEqual(view_look->scale_factor(), 0.0);

    XCTAssertTrue(view_renderer);

    XCTAssertEqual(renderer->system_type(), ui::system_type::none);
    XCTAssertFalse(renderer->metal_system());
}

- (void)test_const_getter {
    std::shared_ptr<ui::renderer const> renderer = ui::renderer::make_shared(nullptr, nullptr, nullptr, nullptr);

    XCTAssertTrue(renderer->root_node());
    XCTAssertFalse(renderer->metal_system());
}

- (void)test_metal_system {
    auto device = objc_ptr_with_move_object(MTLCreateSystemDefaultDevice());
    if (!device) {
        std::cout << "skip : " << __PRETTY_FUNCTION__ << std::endl;
        return;
    }

    auto renderer =
        ui::renderer::make_shared(ui::metal_system::make_shared(device.object()), nullptr, nullptr, nullptr);

    XCTAssertEqual(renderer->system_type(), ui::system_type::metal);
    XCTAssertTrue(renderer->metal_system());
}

- (void)test_view_configure {
    auto device = objc_ptr_with_move_object(MTLCreateSystemDefaultDevice());
    if (!device) {
        std::cout << "skip : " << __PRETTY_FUNCTION__ << std::endl;
        return;
    }

    auto view = [YASTestMetalViewController sharedViewController].metalView;
    [view.window setFrame:CGRectMake(0, 0, 256, 128) display:YES];

    auto const view_look = ui::view_look::make_shared();
    auto const renderer =
        ui::renderer::make_shared(ui::metal_system::make_shared(device.object()), view_look, nullptr, nullptr);
    std::shared_ptr<view_renderer_interface> const view_renderer = renderer;

    XCTAssertEqual(view_look->view_size(), (ui::uint_size{0, 0}));
    XCTAssertEqual(view_look->drawable_size(), (ui::uint_size{0, 0}));

    view_renderer->view_configure(view);

    double const scale_factor = view_look->scale_factor();
    XCTAssertEqual(view.sampleCount, 4);
    XCTAssertEqual(view_look->view_size(), (ui::uint_size{256, 128}));
    XCTAssertEqual(view_look->drawable_size(), (ui::uint_size{static_cast<uint32_t>(256 * scale_factor),
                                                              static_cast<uint32_t>(128 * scale_factor)}));
}

- (void)test_observe_scale_factor {
    auto device = objc_ptr_with_move_object(MTLCreateSystemDefaultDevice());
    if (!device) {
        std::cout << "skip : " << __PRETTY_FUNCTION__ << std::endl;
        return;
    }

    auto view = [YASTestMetalViewController sharedViewController].metalView;
    [view.window setFrame:CGRectMake(0, 0, 256, 128) display:YES];

    auto const view_look = ui::view_look::make_shared();
    auto const renderer =
        ui::renderer::make_shared(ui::metal_system::make_shared(device.object()), view_look, nullptr, nullptr);
    std::shared_ptr<view_renderer_interface> const view_renderer = renderer;

    double notified = 0.0f;

    auto canceller = view_look->observe_scale_factor([&notified](double const &value) { notified = value; }).sync();

    XCTAssertEqual(notified, 0.0f);

    view_renderer->view_configure(view);

    XCTAssertEqual(notified, view_look->scale_factor());
}

@end
