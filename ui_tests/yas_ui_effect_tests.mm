//
//  yas_ui_effect_tests.mm
//

#import <XCTest/XCTest.h>
#import <ui/yas_ui_effect.h>
#import <ui/yas_ui_texture.h>

using namespace yas;

@interface yas_ui_effect_tests : XCTestCase

@end

@implementation yas_ui_effect_tests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)test_create_effect {
    auto effect = ui::effect::make_shared();

    XCTAssertTrue(effect);
    XCTAssertFalse(effect->metal_handler());
    XCTAssertTrue(effect->renderable());
    XCTAssertTrue(effect->encodable());
    XCTAssertTrue(effect->metal());
}

- (void)test_set_metal_handler {
    auto effect = ui::effect::make_shared();

    bool called = false;
    auto handler = [&called](ui::texture_ptr const &src, ui::texture_ptr const &dst, ui::metal_system_ptr const &,
                             id<MTLCommandBuffer> const) { called = true; };

    effect->set_metal_handler(std::move(handler));

    XCTAssertTrue(effect->metal_handler());

    ui::texture_ptr src{nullptr};
    ui::texture_ptr dst{nullptr};
    ui::metal_system_ptr system{nullptr};

    effect->metal_handler()(src, dst, system, nil);

    XCTAssertTrue(called);
}

@end
