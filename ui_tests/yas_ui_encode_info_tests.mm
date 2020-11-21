//
//  yas_ui_encode_info_tests.mm
//

#import <XCTest/XCTest.h>
#import <ui/ui.h>

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
    auto info = ui::metal_encode_info::make_shared({nil, nil, nil});

    XCTAssertTrue(info);
    XCTAssertEqual(info->meshes().size(), 0);
}

- (void)test_append_mesh {
    auto info = ui::metal_encode_info::make_shared({nil, nil, nil});
    auto mesh1 = ui::mesh::make_shared();
    auto mesh2 = ui::mesh::make_shared();

    info->append_mesh(mesh1);

    XCTAssertEqual(info->meshes().size(), 1);

    info->append_mesh(mesh2);

    XCTAssertEqual(info->meshes().size(), 2);

    XCTAssertEqual(info->meshes().at(0), mesh1);
    XCTAssertEqual(info->meshes().at(1), mesh2);
}

@end
