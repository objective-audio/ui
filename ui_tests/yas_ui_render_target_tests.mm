//
//  yas_ui_render_target_tests.mm
//

#import <XCTest/XCTest.h>
#import "yas_ui_render_target.h"
#import "yas_ui_effect.h"

using namespace yas;

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
    ui::render_target render_target;

    XCTAssertEqual(render_target.scale_factor(), 1.0);

    // effectをセットしない場合はデフォルトでthrough_effectが入っている
    XCTAssertTrue(render_target.effect());

    XCTAssertTrue(render_target.renderable());
    XCTAssertTrue(render_target.metal());
}

- (void)test_create_null {
    ui::render_target render_target{nullptr};

    XCTAssertFalse(render_target);
}

- (void)test_set_scale_factor {
    ui::render_target render_target;

    render_target.set_scale_factor(2.0);

    XCTAssertEqual(render_target.scale_factor(), 2.0);
}

- (void)test_set_effect {
    ui::render_target render_target;

    ui::effect effect;

    XCTAssertFalse(render_target.effect() == effect);

    render_target.set_effect(effect);

    XCTAssertTrue(render_target.effect() == effect);
}

@end
