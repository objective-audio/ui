//
//  yas_ui_background_tests.mm
//

#import <XCTest/XCTest.h>
#import <ui/yas_ui_umbrella.h>

using namespace yas;
using namespace yas::ui;

@interface yas_ui_background_tests : XCTestCase

@end

@implementation yas_ui_background_tests

- (void)test_rgb_color {
    auto const background = background::make_shared();

    XCTAssertTrue(background->rgb_color() == (rgb_color{.v = 1.0f}));

    std::vector<rgb_color> called;

    auto canceller =
        background->observe_rgb_color([&called](rgb_color const &color) { called.emplace_back(color); }).sync();

    XCTAssertEqual(called.size(), 1);
    XCTAssertTrue(called.at(0) == (rgb_color{.v = 1.0f}));

    background->set_rgb_color({.red = 1.0f, .green = 0.5f, .blue = 0.25f});

    XCTAssertTrue(background->rgb_color() == (rgb_color{.red = 1.0f, .green = 0.5f, .blue = 0.25f}));
    XCTAssertEqual(called.size(), 2);
    XCTAssertTrue(called.at(1) == (rgb_color{.red = 1.0f, .green = 0.5f, .blue = 0.25f}));
}

- (void)test_alpha {
    auto const background = background::make_shared();

    XCTAssertEqual(background->alpha(), 1.0f);

    std::vector<float> called;

    auto canceller = background->observe_alpha([&called](float const &alpha) { called.emplace_back(alpha); }).sync();

    XCTAssertEqual(called.size(), 1);
    XCTAssertEqual(called.at(0), 1.0f);

    background->set_alpha(0.5f);

    XCTAssertEqual(background->alpha(), 0.5f);
    XCTAssertEqual(called.size(), 2);
    XCTAssertEqual(called.at(1), 0.5f);
}

@end
