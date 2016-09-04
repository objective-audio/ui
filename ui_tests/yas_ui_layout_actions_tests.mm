//
//  yas_ui_layout_actions_tests.mm
//

#import <XCTest/XCTest.h>
#import "yas_ui_layout_actions.h"
#import "yas_ui_layout_guide.h"

using namespace yas;
using namespace std::chrono_literals;

@interface yas_ui_layout_actions_tests : XCTestCase

@end

@implementation yas_ui_layout_actions_tests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)test_update_layout_action {
    ui::layout_guide target;
    auto time = std::chrono::system_clock::now();
    ui::continuous_action::args args{.duration = 1.0, .action = {.start_time = time}};
    auto action = ui::make_action(
        {.target = target, .start_value = 0.0f, .end_value = 1.0f, .continuous_action = std::move(args)});

    auto &updatable = action.updatable();

    updatable.update(time);

    XCTAssertEqual(target.value(), 0.0f);

    updatable.update(time + 500ms);

    XCTAssertEqual(target.value(), 0.5f);

    updatable.update(time + 1s);

    XCTAssertEqual(target.value(), 1.0f);
}

@end
