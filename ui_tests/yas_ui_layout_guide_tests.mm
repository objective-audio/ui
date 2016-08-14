//
//  yas_ui_layout_tests.mm
//

#import <XCTest/XCTest.h>
#import "yas_ui_layout_guide.h"

using namespace yas;

@interface yas_ui_layout_guide_tests : XCTestCase

@end

@implementation yas_ui_layout_guide_tests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)test_create_guide {
    ui::layout_guide guide;

    XCTAssertTrue(guide);
    XCTAssertEqual(guide.value(), 0.0f);
}

- (void)test_create_guide_with_value {
    ui::layout_guide guide{1.0f};

    XCTAssertTrue(guide);
    XCTAssertEqual(guide.value(), 1.0f);
}

- (void)test_create_guide_null {
    ui::layout_guide guide{nullptr};

    XCTAssertFalse(guide);
}

- (void)test_guide_observing {
    ui::layout_guide guide;

    float old_value = -1.0f;
    float new_value = -1.0f;
    ui::layout_guide notified_guide = nullptr;

    auto observer = guide.subject().make_observer(ui::layout_guide::method::value_changed,
                                                  [&old_value, &new_value, &notified_guide](auto const &context) {
                                                      old_value = context.value.old_value;
                                                      new_value = context.value.new_value;
                                                      notified_guide = context.value.layout_guide;
                                                  });

    guide.set_value(10.0f);

    XCTAssertEqual(old_value, 0.0f);
    XCTAssertEqual(new_value, 10.0f);
    XCTAssertTrue(notified_guide);
    XCTAssertEqual(guide, notified_guide);
}

@end
