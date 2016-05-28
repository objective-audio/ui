//
//  yas_ui_encode_info_tests.mm
//

#import <XCTest/XCTest.h>
#import "yas_ui_mesh.h"
#import "yas_ui_metal_encode_info.h"

using namespace yas;

@interface yas_ui_encode_info_tests : XCTestCase

@end

@implementation yas_ui_encode_info_tests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)test_create {
    ui::metal_encode_info info{nil, nil, nil};

    XCTAssertTrue(info);
    XCTAssertEqual(info.meshes().size(), 0);
}

- (void)test_create_null {
    ui::metal_encode_info info{nullptr};

    XCTAssertFalse(info);
}

- (void)test_push_back_mesh {
    ui::metal_encode_info info{nil, nil, nil};
    ui::mesh mesh1;
    ui::mesh mesh2;

    info.push_back_mesh(mesh1);

    XCTAssertEqual(info.meshes().size(), 1);

    info.push_back_mesh(mesh2);

    XCTAssertEqual(info.meshes().size(), 2);

    XCTAssertEqual(info.meshes().at(0), mesh1);
    XCTAssertEqual(info.meshes().at(1), mesh2);
}

@end
