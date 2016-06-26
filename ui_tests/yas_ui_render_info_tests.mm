//
//  yas_ui_render_info_tests.mm
//

#import <XCTest/XCTest.h>
#import "yas_ui_metal_encode_info.h"
#import "yas_ui_render_info.h"

using namespace yas;

@interface yas_ui_render_info_tests : XCTestCase

@end

@implementation yas_ui_render_info_tests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)test_create {
    ui::render_info info;

    XCTAssertFalse(info.collision_detector);
    XCTAssertFalse(info.render_encodable);
}

@end
