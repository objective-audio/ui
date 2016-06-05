//
//  yas_ui_batch_tests.mm
//

#import <XCTest/XCTest.h>
#import "yas_ui_batch.h"
#import "yas_ui_batch_protocol.h"
#import "yas_ui_node.h"

using namespace yas;

@interface yas_ui_batch_tests : XCTestCase

@end

@implementation yas_ui_batch_tests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)test_create {
    ui::batch batch;

    XCTAssertTrue(batch);

    XCTAssertTrue(batch.renderable());
    XCTAssertTrue(batch.encodable());
    XCTAssertTrue(batch.metal());
}

- (void)test_create_null {
    ui::batch batch{nullptr};

    XCTAssertFalse(batch);
}

@end
