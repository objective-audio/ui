//
//  yas_ui_detector_tests.mm
//

#import <XCTest/XCTest.h>
#import <ui/ui.h>

using namespace yas;

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
    auto detector = ui::detector::make_shared();

    XCTAssertTrue(detector);

    XCTAssertTrue(ui::renderer_detector_interface::cast(detector));
}

- (void)test_detect {
    auto detector = ui::detector::make_shared();

    XCTAssertFalse(detector->detect({.v = 0.0f}));

    auto collider1 =
        ui::collider::make_shared(ui::shape::make_shared({.rect = {.origin = {-0.5f, -0.5f}, .size = {1.0f, 1.0f}}}));
    auto collider2 =
        ui::collider::make_shared(ui::shape::make_shared({.rect = {.origin = {-0.5f, -0.5f}, .size = {1.0f, 1.0f}}}));

    auto const renderer_detector = ui::renderer_detector_interface::cast(detector);
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
    auto detector = ui::detector::make_shared();

    auto collider1 =
        ui::collider::make_shared(ui::shape::make_shared({.rect = {.origin = {-0.5f, -0.5f}, .size = {1.0f, 1.0f}}}));
    auto collider2 =
        ui::collider::make_shared(ui::shape::make_shared({.rect = {.origin = {-0.5f, -0.5f}, .size = {1.0f, 1.0f}}}));

    auto const updatable = ui::renderer_detector_interface::cast(detector);
    updatable->push_front_collider(collider1);
    updatable->push_front_collider(collider2);

    XCTAssertFalse(detector->detect({.v = 0.0f}, collider1));
    XCTAssertTrue(detector->detect({.v = 0.0f}, collider2));
}

- (void)test_is_updating {
    auto detector = ui::detector::make_shared();
    auto const updatable = ui::renderer_detector_interface::cast(detector);

    XCTAssertTrue(updatable->is_updating());

    updatable->begin_update();

    XCTAssertTrue(updatable->is_updating());

    updatable->end_update();

    XCTAssertFalse(updatable->is_updating());

    updatable->begin_update();

    XCTAssertTrue(updatable->is_updating());
}

@end
