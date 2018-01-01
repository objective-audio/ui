//
//  yas_ui_effect_tests.mm
//

#import <XCTest/XCTest.h>
#import "yas_ui_effect.h"
#import "yas_ui_texture.h"

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
    ui::effect effect;

    XCTAssertTrue(effect);
    XCTAssertFalse(effect.metal_handler());
    XCTAssertTrue(effect.renderable());
    XCTAssertTrue(effect.encodable());
    XCTAssertTrue(effect.metal());
}

- (void)test_create_null {
    ui::effect effect{nullptr};

    XCTAssertFalse(effect);
}

- (void)test_set_metal_handler {
    ui::effect effect;

    bool called = false;
    auto handler = [&called](ui::texture &src, ui::texture &dst, ui::metal_system &, id<MTLCommandBuffer> const) {
        called = true;
    };

    effect.set_metal_handler(std::move(handler));

    XCTAssertTrue(effect.metal_handler());

    ui::texture src{nullptr};
    ui::texture dst{nullptr};
    ui::metal_system system{nullptr};

    effect.metal_handler()(src, dst, system, nil);

    XCTAssertTrue(called);
}

@end
