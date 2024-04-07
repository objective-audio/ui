//
//  yas_ui_view_look_tests.mm
//

#import <XCTest/XCTest.h>
#import <ui/yas_ui_umbrella.h>

using namespace yas;
using namespace yas::ui;

@interface yas_ui_view_look_tests : XCTestCase

@end

@implementation yas_ui_view_look_tests

- (void)setUp {
}

- (void)tearDown {
}

- (void)test_set_view_sizes {
    auto const view_look = ui::view_look::make_shared();

    XCTAssertEqual(view_look->view_size(), (ui::uint_size{0, 0}));
    XCTAssertEqual(view_look->drawable_size(), (ui::uint_size{0, 0}));

    view_look->set_view_sizes({256, 128}, {512, 256}, {0, 0, 0, 0});

    double const scale_factor = view_look->scale_factor();
    XCTAssertEqual(view_look->view_size(), (ui::uint_size{256, 128}));
    XCTAssertEqual(view_look->drawable_size(), (ui::uint_size{static_cast<uint32_t>(256 * scale_factor),
                                                              static_cast<uint32_t>(128 * scale_factor)}));
}

- (void)test_observe_view_layout_guide {
    auto const view_look = ui::view_look::make_shared();

    XCTAssertEqual(view_look->view_size(), (uint_size{0, 0}));

    view_look->set_view_sizes({16, 16}, {32, 32}, {0, 0, 0, 0});

    XCTAssertEqual(view_look->view_size(), (uint_size{16, 16}));

    XCTestExpectation *expectation = [self expectationWithDescription:@"view_size_changed"];

    auto canceller =
        view_look->view_layout_guide()->observe([&expectation](region const &) { [expectation fulfill]; }).end();

    view_look->set_view_sizes({32, 32}, {64, 64}, {0, 0, 0, 0});

    [self waitForExpectations:@[expectation] timeout:1.0];

    XCTAssertEqual(view_look->view_size(), (uint_size{32, 32}));

    canceller->cancel();
}

- (void)test_observe_scale_factor {
    auto const view_look = ui::view_look::make_shared();

    double notified = 0.0f;

    auto canceller = view_look->observe_scale_factor([&notified](double const &value) { notified = value; }).sync();

    XCTAssertEqual(notified, 0.0f);

    view_look->set_view_sizes({256, 128}, {512, 256}, {0, 0, 0, 0});

    XCTAssertNotEqual(notified, 0.0f);
    XCTAssertEqual(notified, view_look->scale_factor());

    canceller->cancel();
}

@end
