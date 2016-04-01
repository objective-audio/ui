//
//  yas_ui_metal_view_tests.mm
//

#import <XCTest/XCTest.h>
#import <iostream>
#import "yas_base.h"
#import "yas_objc_ptr.h"
#import "yas_ui_metal_view.h"
#import "yas_ui_renderer_protocol.h"

using namespace yas;

namespace yas {
namespace test {
    struct dummy_renderer : public base {
        struct impl : public base::impl, public ui::view_renderable::impl {
            void view_configure(YASUIMetalView *const view) override {
            }

            void view_drawable_size_will_change(YASUIMetalView *const view, CGSize const size) override {
                drawable_size_will_change_called = true;
                drawable_size = size;
            }

            void view_render(YASUIMetalView *const view) override {
                render_called = true;
            }

            void reset() {
                drawable_size_will_change_called = false;
                drawable_size = CGSizeZero;
                render_called = false;
            }

            bool drawable_size_will_change_called;
            CGSize drawable_size;
            bool render_called;
        };

        dummy_renderer() : base(std::make_shared<impl>()) {
        }

        ui::view_renderable renderable() {
            return ui::view_renderable{impl_ptr<ui::view_renderable::impl>()};
        }
    };
}
}

@interface yas_ui_metal_view_mac_tests : XCTestCase

@end

@implementation yas_ui_metal_view_mac_tests {
}

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

    auto view_object = make_objc_ptr([[YASUIMetalView alloc] initWithFrame:CGRectMake(0, 0, 512, 256)]);
    auto view = view_object.object();

    XCTAssertFalse(view.renderer);
    XCTAssertNotNil(view.device);
    XCTAssertEqualObjects(view.device, device.object());
    XCTAssertNotNil(view.currentDrawable);
    XCTAssertNil(view.renderPassDescriptor);
    XCTAssertEqual(view.sampleCount, 1);
    XCTAssertFalse(view.paused);
}

- (void)test_renderable {
    auto device = make_objc_ptr(MTLCreateSystemDefaultDevice());
    if (!device) {
        std::cout << "skip : " << __PRETTY_FUNCTION__ << std::endl;
        return;
    }

    auto view_object = make_objc_ptr([[YASUIMetalView alloc] initWithFrame:CGRectMake(0, 0, 512, 256)]);
    auto view = view_object.object();

    test::dummy_renderer renderer;
    auto renderer_impl_ptr = renderer.impl_ptr<test::dummy_renderer::impl>();
    view.renderer = renderer.renderable();

    XCTAssertTrue(view.renderer);

    renderer_impl_ptr->reset();
    [view draw];

    XCTAssertTrue(renderer_impl_ptr->drawable_size_will_change_called);
    XCTAssertTrue(CGSizeEqualToSize(renderer_impl_ptr->drawable_size, CGSizeMake(512, 256)));
    XCTAssertTrue(renderer_impl_ptr->render_called);

    renderer_impl_ptr->reset();
    [view draw];

    XCTAssertFalse(renderer_impl_ptr->drawable_size_will_change_called);
    XCTAssertTrue(renderer_impl_ptr->render_called);
}

@end
