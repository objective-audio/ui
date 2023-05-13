//
//  yas_ui_detector_tests.mm
//

#import <XCTest/XCTest.h>
#import <ui/yas_ui_umbrella.h>

using namespace yas;
using namespace yas::ui;

@interface yas_ui_detector_tests : XCTestCase

@end

@implementation yas_ui_detector_tests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)test_create {
    auto detector = detector::make_shared();

    XCTAssertTrue(detector);

    XCTAssertTrue(detector_for_renderer::cast(detector));
}

- (void)test_detect {
    auto detector = detector::make_shared();

    XCTAssertFalse(detector->detect({.v = 0.0f}));

    auto collider1 =
        collider::make_shared(shape::make_shared({.rect = {.origin = {-0.5f, -0.5f}, .size = {1.0f, 1.0f}}}));
    auto collider2 =
        collider::make_shared(shape::make_shared({.rect = {.origin = {-0.5f, -0.5f}, .size = {1.0f, 1.0f}}}));

    auto const renderer_detector = detector_for_renderer::cast(detector);
    renderer_detector->begin_update();
    renderer_detector->push_front_collider(collider1);
    renderer_detector->push_front_collider(collider2);
    renderer_detector->end_update();

    XCTAssertEqual(detector->detect({.v = 0.0f}), collider2);

    renderer_detector->begin_update();
    renderer_detector->end_update();

    XCTAssertFalse(detector->detect({.v = 0.0f}));
}

- (void)test_detect_with_collider {
    auto detector = detector::make_shared();

    auto collider1 =
        collider::make_shared(shape::make_shared({.rect = {.origin = {-0.5f, -0.5f}, .size = {1.0f, 1.0f}}}));
    auto collider2 =
        collider::make_shared(shape::make_shared({.rect = {.origin = {-0.5f, -0.5f}, .size = {1.0f, 1.0f}}}));

    auto const updatable = detector_for_renderer::cast(detector);
    updatable->push_front_collider(collider1);
    updatable->push_front_collider(collider2);

    XCTAssertFalse(detector->detect({.v = 0.0f}, collider1));
    XCTAssertTrue(detector->detect({.v = 0.0f}, collider2));
}

- (void)test_is_updating {
    auto detector = detector::make_shared();
    auto const updatable = detector_for_renderer::cast(detector);

    XCTAssertTrue(updatable->is_updating());

    updatable->begin_update();

    XCTAssertTrue(updatable->is_updating());

    updatable->end_update();

    XCTAssertFalse(updatable->is_updating());

    updatable->begin_update();

    XCTAssertTrue(updatable->is_updating());
}

@end
