//
//  yas_ui_batch_tests.mm
//

#import <XCTest/XCTest.h>
#import <iostream>
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

- (void)test_batch_building_type_to_string {
    XCTAssertEqual(to_string(ui::batch_building_type::rebuild), "rebuild");
    XCTAssertEqual(to_string(ui::batch_building_type::overwrite), "overwrite");
    XCTAssertEqual(to_string(ui::batch_building_type::none), "none");
}

- (void)test_batch_building_type_ostream {
    std::cout << ui::batch_building_type::rebuild << std::endl;
    std::cout << ui::batch_building_type::overwrite << std::endl;
    std::cout << ui::batch_building_type::none << std::endl;
}

@end
