//
//  yas_ui_renderer_tests.mm
//

#import <XCTest/XCTest.h>
#import <cpp_utils/yas_objc_ptr.h>
#import <ui/yas_ui_umbrella.h>
#import <iostream>
#import <sstream>
#import "yas_test_metal_view_controller.h"

using namespace yas;

@interface yas_ui_renderer_tests : XCTestCase

@end

@implementation yas_ui_renderer_tests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [[YASTestMetalViewController sharedViewController] setRenderable:nullptr];
    [super tearDown];
}

- (void)test_create {
    auto renderer = ui::renderer::make_shared();

    XCTAssertFalse(renderer->metal_system());

    XCTAssertTrue(renderer->root_node());
    XCTAssertEqual(renderer->actions().size(), 0);

    XCTAssertEqual(renderer->view_size(), (ui::uint_size{0, 0}));
    XCTAssertEqual(renderer->drawable_size(), (ui::uint_size{0, 0}));
    XCTAssertEqual(renderer->scale_factor(), 0.0);

    XCTAssertTrue(ui::view_renderable::cast(renderer));
    XCTAssertTrue(renderer->event_manager());
    XCTAssertTrue(renderer->detector());

    XCTAssertEqual(renderer->system_type(), ui::system_type::none);
    XCTAssertFalse(renderer->metal_system());
}

- (void)test_const_getter {
    std::shared_ptr<ui::renderer const> renderer = ui::renderer::make_shared();

    XCTAssertTrue(renderer->root_node());
    XCTAssertTrue(renderer->detector());
    XCTAssertFalse(renderer->metal_system());
}

- (void)test_metal_system {
    auto device = objc_ptr_with_move_object(MTLCreateSystemDefaultDevice());
    if (!device) {
        std::cout << "skip : " << __PRETTY_FUNCTION__ << std::endl;
        return;
    }

    auto renderer = ui::renderer::make_shared(ui::metal_system::make_shared(device.object()));

    XCTAssertEqual(renderer->system_type(), ui::system_type::metal);
    XCTAssertTrue(renderer->metal_system());
}

- (void)test_action {
    auto renderer = ui::renderer::make_shared();

    auto target1 = ui::node::make_shared();
    auto target2 = ui::node::make_shared();
    auto action1 = ui::action::make_shared();
    auto action2 = ui::action::make_shared();
    action1->set_target(target1);
    action2->set_target(target2);

    renderer->insert_action(action1);

    XCTAssertEqual(renderer->actions().size(), 1);
    XCTAssertEqual(renderer->actions().at(0), action1);

    renderer->insert_action(action2);

    XCTAssertEqual(renderer->actions().size(), 2);

    renderer->erase_action(target1);

    XCTAssertEqual(renderer->actions().size(), 1);
    XCTAssertEqual(renderer->actions().at(0), action2);

    renderer->erase_action(action2);

    XCTAssertEqual(renderer->actions().size(), 0);
}

- (void)test_view_configure {
    auto device = objc_ptr_with_move_object(MTLCreateSystemDefaultDevice());
    if (!device) {
        std::cout << "skip : " << __PRETTY_FUNCTION__ << std::endl;
        return;
    }

    auto view = [YASTestMetalViewController sharedViewController].metalView;
    [view.window setFrame:CGRectMake(0, 0, 256, 128) display:YES];

    auto renderer = ui::renderer::make_shared(ui::metal_system::make_shared(device.object()));

    XCTAssertEqual(renderer->view_size(), (ui::uint_size{0, 0}));
    XCTAssertEqual(renderer->drawable_size(), (ui::uint_size{0, 0}));

    ui::view_renderable::cast(renderer)->view_configure(view);

    double const scale_factor = renderer->scale_factor();
    XCTAssertEqual(view.sampleCount, 4);
    XCTAssertEqual(renderer->view_size(), (ui::uint_size{256, 128}));
    XCTAssertEqual(renderer->drawable_size(), (ui::uint_size{static_cast<uint32_t>(256 * scale_factor),
                                                             static_cast<uint32_t>(128 * scale_factor)}));
}

- (void)test_method_to_string {
    XCTAssertEqual(to_string(ui::renderer::method::will_render), "will_render");
    XCTAssertEqual(to_string(ui::renderer::method::view_size_changed), "view_size_changed");
    XCTAssertEqual(to_string(ui::renderer::method::safe_area_insets_changed), "safe_area_insets_changed");
    XCTAssertEqual(to_string(ui::renderer::method::scale_factor_changed), "scale_factor_changed");
}

- (void)test_method_ostream {
    auto const methods = {ui::renderer::method::will_render, ui::renderer::method::view_size_changed,
                          ui::renderer::method::safe_area_insets_changed, ui::renderer::method::scale_factor_changed};

    for (auto const &method : methods) {
        std::ostringstream stream;
        stream << method;
        XCTAssertEqual(stream.str(), to_string(method));
    }
}

- (void)test_chain_scale_factor {
    auto device = objc_ptr_with_move_object(MTLCreateSystemDefaultDevice());
    if (!device) {
        std::cout << "skip : " << __PRETTY_FUNCTION__ << std::endl;
        return;
    }

    auto view = [YASTestMetalViewController sharedViewController].metalView;
    [view.window setFrame:CGRectMake(0, 0, 256, 128) display:YES];

    auto renderer = ui::renderer::make_shared(ui::metal_system::make_shared(device.object()));

    double notified = 0.0f;

    auto observer =
        renderer->chain_scale_factor().perform([&notified](double const &value) { notified = value; }).sync();

    XCTAssertEqual(notified, 0.0f);

    ui::view_renderable::cast(renderer)->view_configure(view);

    XCTAssertEqual(notified, renderer->scale_factor());
}

@end
