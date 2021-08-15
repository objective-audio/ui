//
//  yas_ui_render_target_tests.mm
//

#import <XCTest/XCTest.h>
#import <ui/ui.h>
#import "yas_ui_view_look_stubs.h"

using namespace yas;
using namespace yas::ui;

@interface yas_ui_render_target_tests : XCTestCase

@end

@implementation yas_ui_render_target_tests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)test_create_render_target {
    auto const view_look = view_look_scale_factor_stub::make_shared(1.0);
    auto const render_target = render_target::make_shared(view_look);

    XCTAssertEqual(render_target->scale_factor(), 1.0);

    // effectをセットしない場合はデフォルトでthrough_effectが入っている
    XCTAssertTrue(render_target->effect());
}

- (void)test_observe_scale_factor {
    auto const view_look = view_look_scale_factor_stub::make_shared(1.0);
    auto const render_target = render_target::make_shared(view_look);

    view_look->scale_factor_holder->set_value(2.0);

    XCTAssertEqual(render_target->scale_factor(), 2.0);
}

- (void)test_set_effect {
    auto const view_look = view_look_scale_factor_stub::make_shared(1.0);
    auto const render_target = render_target::make_shared(view_look);

    auto effect = effect::make_shared();

    XCTAssertFalse(render_target->effect() == effect);

    render_target->set_effect(effect);

    XCTAssertTrue(render_target->effect() == effect);
}

@end
