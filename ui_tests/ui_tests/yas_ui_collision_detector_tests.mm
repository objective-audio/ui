//
//  yas_ui_collision_detector_tests.mm
//

#import <XCTest/XCTest.h>
#import "yas_ui_collider.h"
#import "yas_ui_collision_detector.h"

using namespace yas;

@interface yas_ui_collision_detector_tests : XCTestCase

@end

@implementation yas_ui_collision_detector_tests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)test_create {
    ui::collision_detector detector;

    XCTAssertTrue(detector);
    XCTAssertTrue(detector.updatable());
}

- (void)test_create_null {
    ui::collision_detector detector{nullptr};

    XCTAssertFalse(detector);
}

- (void)test_detect {
    ui::collision_detector detector;

    XCTAssertFalse(detector.detect(0.0f));

    ui::collider collider1{{.shape = ui::collider_shape::square}};
    ui::collider collider2{{.shape = ui::collider_shape::square}};

    detector.updatable().push_front_collider_if_needed(collider1);
    detector.updatable().push_front_collider_if_needed(collider2);

    XCTAssertEqual(detector.detect(0.0f), collider2);

    detector.updatable().clear_colliders_if_needed();

    XCTAssertFalse(detector.detect(0.0f));
}

- (void)test_detect_with_collider {
    ui::collision_detector detector;

    ui::collider collider1{{.shape = ui::collider_shape::square}};
    ui::collider collider2{{.shape = ui::collider_shape::square}};

    detector.updatable().push_front_collider_if_needed(collider1);
    detector.updatable().push_front_collider_if_needed(collider2);

    XCTAssertFalse(detector.detect(0.0f, collider1));
    XCTAssertTrue(detector.detect(0.0f, collider2));
}

- (void)test_needs_update {
    ui::collision_detector detector;

    ui::collider collider1{{.shape = ui::collider_shape::square}};

    detector.updatable().push_front_collider_if_needed(collider1);

    XCTAssertTrue(detector.detect(0.0f, collider1));

    detector.updatable().finalize();
    detector.updatable().clear_colliders_if_needed();

    XCTAssertTrue(detector.detect(0.0f, collider1));

    detector.updatable().set_needs_update_colliders();
    detector.updatable().clear_colliders_if_needed();

    XCTAssertFalse(detector.detect(0.0f, collider1));
    
    detector.updatable().finalize();
    detector.updatable().push_front_collider_if_needed(collider1);
    
    XCTAssertFalse(detector.detect(0.0f, collider1));
}

@end
