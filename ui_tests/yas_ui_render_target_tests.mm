//
//  yas_ui_render_target_tests.mm
//

#import <XCTest/XCTest.h>
#import <ui/yas_ui_effect.h>
#import <ui/yas_ui_render_target.h>

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
    auto render_target = ui::render_target::make_shared();

    XCTAssertEqual(render_target->scale_factor(), 1.0);

    // effectをセットしない場合はデフォルトでthrough_effectが入っている
    XCTAssertTrue(render_target->effect());

    XCTAssertTrue(ui::renderable_render_target::cast(render_target));
    XCTAssertTrue(ui::metal_object::cast(render_target));
}

- (void)test_set_scale_factor {
    auto render_target = ui::render_target::make_shared();

    render_target->set_scale_factor(2.0);

    XCTAssertEqual(render_target->scale_factor(), 2.0);
}

- (void)test_set_effect {
    auto render_target = ui::render_target::make_shared();

    auto effect = ui::effect::make_shared();

    XCTAssertFalse(render_target->effect() == effect);

    render_target->set_effect(effect);

    XCTAssertTrue(render_target->effect() == effect);
}

@end
