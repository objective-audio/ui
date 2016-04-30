//
//  yas_ui_render_info_tests.mm
//

#import <XCTest/XCTest.h>
#import "yas_ui_encode_info.h"
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

    XCTAssertFalse(info.current_encode_info());
    XCTAssertEqual(info.all_encode_infos.size(), 0);
}

- (void)test_push_and_pop_encode_info {
    ui::render_info info;

    info.push_encode_info({nil, nil, nil});

    XCTAssertEqual(info.all_encode_infos.size(), 1);

    auto encode_info1 = info.current_encode_info();
    XCTAssertTrue(encode_info1);

    info.push_encode_info({nil, nil, nil});

    XCTAssertEqual(info.all_encode_infos.size(), 2);

    auto encode_info2 = info.current_encode_info();
    XCTAssertTrue(encode_info2);

    info.pop_endoce_info();

    XCTAssertEqual(info.all_encode_infos.size(), 2);
    XCTAssertEqual(info.current_encode_info(), encode_info1);

    info.pop_endoce_info();

    XCTAssertEqual(info.all_encode_infos.size(), 2);
    XCTAssertFalse(info.current_encode_info());
}

@end
