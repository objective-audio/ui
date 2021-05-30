//
//  yas_ui_effect_tests.mm
//

#import <XCTest/XCTest.h>
#import <ui/ui.h>

using namespace yas;
using namespace yas::ui;

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
    auto effect = effect::make_shared();

    XCTAssertTrue(effect);
    XCTAssertFalse(effect->metal_handler());
    XCTAssertTrue(renderable_effect::cast(effect));
    XCTAssertTrue(encodable_effect::cast(effect));
    XCTAssertTrue(metal_object::cast(effect));
}

- (void)test_set_metal_handler {
    auto effect = effect::make_shared();

    bool called = false;
    auto handler = [&called](std::shared_ptr<texture> const &src, std::shared_ptr<texture> const &dst,
                             std::shared_ptr<metal_system> const &, id<MTLCommandBuffer> const) { called = true; };

    effect->set_metal_handler(std::move(handler));

    XCTAssertTrue(effect->metal_handler());

    std::shared_ptr<texture> src{nullptr};
    std::shared_ptr<texture> dst{nullptr};
    std::shared_ptr<metal_system> system{nullptr};

    effect->metal_handler()(src, dst, system, nil);

    XCTAssertTrue(called);
}

@end
