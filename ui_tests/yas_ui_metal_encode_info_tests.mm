//
//  yas_ui_metal_encode_info_tests.mm
//

#import <XCTest/XCTest.h>
#import "yas_ui_mesh.h"
#import "yas_ui_metal_encode_info.h"

using namespace yas;

@interface yas_ui_metal_encode_info_tests : XCTestCase

@end

@implementation yas_ui_metal_encode_info_tests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)test_create {
    ui::metal_encode_info info{{nil, nil, nil}};

    XCTAssertTrue(info);

    XCTAssertNil(info.renderPassDescriptor());
    XCTAssertNil(info.pipelineStateWithTexture());
    XCTAssertNil(info.pipelineStateWithoutTexture());
    XCTAssertEqual(info.meshes().size(), 0);
}

- (void)test_create_null {
    ui::metal_encode_info info{nullptr};

    XCTAssertFalse(info);
}

- (void)test_set_mesh {
    ui::metal_encode_info info{{nil, nil, nil}};

    info.push_back_mesh(ui::mesh{});

    XCTAssertEqual(info.meshes().size(), 1);

    info.push_back_mesh(ui::mesh{});

    XCTAssertEqual(info.meshes().size(), 2);
}

@end
