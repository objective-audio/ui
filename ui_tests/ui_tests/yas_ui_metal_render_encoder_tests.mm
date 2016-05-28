//
//  yas_ui_metal_render_encoder_tests.mm
//

#import <XCTest/XCTest.h>
#import "yas_ui_metal_encode_info.h"
#import "yas_ui_metal_render_encoder.h"

using namespace yas;

@interface yas_ui_metal_render_encoder_tests : XCTestCase

@end

@implementation yas_ui_metal_render_encoder_tests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)test_create {
}

- (void)test_create_null {
    ui::metal_render_encoder encoder{nullptr};

    XCTAssertFalse(encoder);
}

- (void)test_push_and_pop_encode_info {
    ui::metal_render_encoder encoder;

    encoder.push_encode_info({nil, nil, nil});

    XCTAssertEqual(encoder.all_encode_infos().size(), 1);

    auto encode_info1 = encoder.current_encode_info();
    XCTAssertTrue(encode_info1);

    encoder.push_encode_info({nil, nil, nil});

    XCTAssertEqual(encoder.all_encode_infos().size(), 2);

    auto encode_info2 = encoder.current_encode_info();
    XCTAssertTrue(encode_info2);

    encoder.pop_encode_info();

    XCTAssertEqual(encoder.all_encode_infos().size(), 2);
    XCTAssertEqual(encoder.current_encode_info(), encode_info1);

    encoder.pop_encode_info();

    XCTAssertEqual(encoder.all_encode_infos().size(), 2);
    XCTAssertFalse(encoder.current_encode_info());
}

@end
