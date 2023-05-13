//
//  yas_ui_metal_types_tests.mm
//

#import <XCTest/XCTest.h>
#import <ui/yas_ui_umbrella.h>

using namespace yas;
using namespace yas::ui;

@interface yas_ui_metal_types_tests : XCTestCase

@end

@implementation yas_ui_metal_types_tests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)test_to_mtl_origin {
    uint_point point{2, 5};

    auto mtl_origin = to_mtl_origin(point);

    XCTAssertEqual(mtl_origin.x, 2);
    XCTAssertEqual(mtl_origin.y, 5);
    XCTAssertEqual(mtl_origin.z, 0);
}

- (void)test_to_mtl_size {
    uint_size size{3, 17};

    auto mtl_size = to_mtl_size(size);

    XCTAssertEqual(mtl_size.width, 3);
    XCTAssertEqual(mtl_size.height, 17);
    XCTAssertEqual(mtl_size.depth, 1);
}

- (void)test_to_mtl_region {
    uint_region region{4, 2, 38, 888};

    auto mtl_region = to_mtl_region(region);

    XCTAssertEqual(mtl_region.origin.x, 4);
    XCTAssertEqual(mtl_region.origin.y, 2);
    XCTAssertEqual(mtl_region.size.width, 38);
    XCTAssertEqual(mtl_region.size.height, 888);

    XCTAssertEqual(mtl_region.origin.z, 0);
    XCTAssertEqual(mtl_region.size.depth, 1);
}

- (void)test_to_uint_point {
    MTLOrigin mtl_origin = MTLOriginMake(2, 5, 0);

    auto origin = to_uint_point(mtl_origin);

    XCTAssertEqual(origin.x, 2);
    XCTAssertEqual(origin.y, 5);
}

- (void)test_to_uint_size {
    MTLSize mtl_size = MTLSizeMake(76, 9, 1);

    auto size = to_uint_size(mtl_size);

    XCTAssertEqual(size.width, 76);
    XCTAssertEqual(size.height, 9);
}

- (void)test_to_uint_region {
    MTLRegion mtl_region = MTLRegionMake2D(36, 100, 9, 32);

    auto region = to_uint_region(mtl_region);

    XCTAssertEqual(region.origin.x, 36);
    XCTAssertEqual(region.origin.y, 100);
    XCTAssertEqual(region.size.width, 9);
    XCTAssertEqual(region.size.height, 32);
}

- (void)test_to_mtl_primitive_type {
    XCTAssertEqual(to_mtl_primitive_type(primitive_type::point), MTLPrimitiveTypePoint);
    XCTAssertEqual(to_mtl_primitive_type(primitive_type::line), MTLPrimitiveTypeLine);
    XCTAssertEqual(to_mtl_primitive_type(primitive_type::line_strip), MTLPrimitiveTypeLineStrip);
    XCTAssertEqual(to_mtl_primitive_type(primitive_type::triangle), MTLPrimitiveTypeTriangle);
    XCTAssertEqual(to_mtl_primitive_type(primitive_type::triangle_strip), MTLPrimitiveTypeTriangleStrip);
}

@end
