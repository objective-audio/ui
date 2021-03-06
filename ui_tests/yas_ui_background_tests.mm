//
//  yas_ui_background_tests.mm
//

#import <XCTest/XCTest.h>
#import <ui/ui.h>

using namespace yas;
using namespace yas::ui;

@interface yas_ui_background_tests : XCTestCase

@end

@implementation yas_ui_background_tests

- (void)test_color {
    auto const background = background::make_shared();

    XCTAssertTrue(background->color() == (color{.v = 1.0f}));

    std::vector<color> called;

    auto canceller = background->observe_color([&called](color const &color) { called.emplace_back(color); }).sync();

    XCTAssertEqual(called.size(), 1);
    XCTAssertTrue(called.at(0) == (color{.v = 1.0f}));

    background->set_color({.red = 1.0f, .green = 0.5f, .blue = 0.25f});

    XCTAssertTrue(background->color() == (color{.red = 1.0f, .green = 0.5f, .blue = 0.25f}));
    XCTAssertEqual(called.size(), 2);
    XCTAssertTrue(called.at(1) == (color{.red = 1.0f, .green = 0.5f, .blue = 0.25f}));
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
