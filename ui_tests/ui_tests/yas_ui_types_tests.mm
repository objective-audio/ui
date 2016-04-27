//
//  yas_ui_types_tests.mm
//

#import <XCTest/XCTest.h>
#import "yas_ui_types.h"

#import <iostream>

using namespace yas;

@interface yas_ui_types_tests : XCTestCase

@end

@implementation yas_ui_types_tests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)test_to_mtl_origin {
    ui::uint_origin origin{2, 5};

    auto mtl_origin = to_mtl_origin(origin);

    XCTAssertEqual(mtl_origin.x, 2);
    XCTAssertEqual(mtl_origin.y, 5);
    XCTAssertEqual(mtl_origin.z, 0);
}

- (void)test_to_mtl_size {
    ui::uint_size size{3, 17};

    auto mtl_size = to_mtl_size(size);

    XCTAssertEqual(mtl_size.width, 3);
    XCTAssertEqual(mtl_size.height, 17);
    XCTAssertEqual(mtl_size.depth, 1);
}

- (void)test_to_mtl_region {
    ui::uint_region region{4, 2, 38, 888};

    auto mtl_region = to_mtl_region(region);

    XCTAssertEqual(mtl_region.origin.x, 4);
    XCTAssertEqual(mtl_region.origin.y, 2);
    XCTAssertEqual(mtl_region.size.width, 38);
    XCTAssertEqual(mtl_region.size.height, 888);

    XCTAssertEqual(mtl_region.origin.z, 0);
    XCTAssertEqual(mtl_region.size.depth, 1);
}

- (void)test_to_uint_origin {
    MTLOrigin mtl_origin = MTLOriginMake(2, 5, 0);

    auto origin = to_uint_origin(mtl_origin);

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

- (void)test_is_equal_uint_origin {
    auto origin1_2a = ui::uint_origin{1, 2};
    auto origin1_2b = ui::uint_origin{1, 2};
    auto origin1_3 = ui::uint_origin{1, 3};
    auto origin2_2 = ui::uint_origin{2, 2};

    XCTAssertTrue(origin1_2a == origin1_2a);
    XCTAssertTrue(origin1_2a == origin1_2b);
    XCTAssertFalse(origin1_2a == origin1_3);
    XCTAssertFalse(origin1_2a == origin2_2);

    XCTAssertFalse(origin1_2a != origin1_2a);
    XCTAssertFalse(origin1_2a != origin1_2b);
    XCTAssertTrue(origin1_2a != origin1_3);
    XCTAssertTrue(origin1_2a != origin2_2);
}

- (void)test_is_equal_uint_size {
    auto size1_2a = ui::uint_size{1, 2};
    auto size1_2b = ui::uint_size{1, 2};
    auto size1_3 = ui::uint_size{1, 3};
    auto size2_2 = ui::uint_size{2, 2};

    XCTAssertTrue(size1_2a == size1_2a);
    XCTAssertTrue(size1_2a == size1_2b);
    XCTAssertFalse(size1_2a == size1_3);
    XCTAssertFalse(size1_2a == size2_2);

    XCTAssertFalse(size1_2a != size1_2a);
    XCTAssertFalse(size1_2a != size1_2b);
    XCTAssertTrue(size1_2a != size1_3);
    XCTAssertTrue(size1_2a != size2_2);
}

- (void)test_is_equal_uint_region {
    auto origin_a1 = ui::uint_origin{1, 2};
    auto origin_a2 = ui::uint_origin{1, 2};
    auto origin_b = ui::uint_origin{3, 4};

    auto size_a1 = ui::uint_size{5, 6};
    auto size_a2 = ui::uint_size{5, 6};
    auto size_b = ui::uint_size{7, 8};

    auto region_a1_a1 = ui::uint_region{origin_a1, size_a1};
    auto region_a1_a2 = ui::uint_region{origin_a1, size_a2};
    auto region_a2_a1 = ui::uint_region{origin_a2, size_a1};
    auto region_a2_a2 = ui::uint_region{origin_a2, size_a2};
    auto region_b = ui::uint_region{origin_b, size_b};

    XCTAssertTrue(region_a1_a1 == region_a1_a1);
    XCTAssertTrue(region_a1_a1 == region_a1_a2);
    XCTAssertTrue(region_a1_a1 == region_a2_a1);
    XCTAssertTrue(region_a1_a1 == region_a2_a2);
    XCTAssertFalse(region_a1_a1 == region_b);

    XCTAssertFalse(region_a1_a1 != region_a1_a1);
    XCTAssertFalse(region_a1_a1 != region_a1_a2);
    XCTAssertFalse(region_a1_a1 != region_a2_a1);
    XCTAssertFalse(region_a1_a1 != region_a2_a2);
    XCTAssertTrue(region_a1_a1 != region_b);
}

- (void)test_is_equal_float_origin {
    auto origin1_2a = ui::float_origin{1.0f, 2.0f};
    auto origin1_2b = ui::float_origin{1.0f, 2.0f};
    auto origin1_3 = ui::float_origin{1.0f, 3.0f};
    auto origin2_2 = ui::float_origin{2, 2};

    XCTAssertTrue(origin1_2a == origin1_2a);
    XCTAssertTrue(origin1_2a == origin1_2b);
    XCTAssertFalse(origin1_2a == origin1_3);
    XCTAssertFalse(origin1_2a == origin2_2);

    XCTAssertFalse(origin1_2a != origin1_2a);
    XCTAssertFalse(origin1_2a != origin1_2b);
    XCTAssertTrue(origin1_2a != origin1_3);
    XCTAssertTrue(origin1_2a != origin2_2);
}

- (void)test_is_equal_float_size {
    auto size1_2a = ui::float_size{1.0f, 2.0f};
    auto size1_2b = ui::float_size{1.0f, 2.0f};
    auto size1_3 = ui::float_size{1.0f, 3.0f};
    auto size2_2 = ui::float_size{2.0f, 2.0f};

    XCTAssertTrue(size1_2a == size1_2a);
    XCTAssertTrue(size1_2a == size1_2b);
    XCTAssertFalse(size1_2a == size1_3);
    XCTAssertFalse(size1_2a == size2_2);

    XCTAssertFalse(size1_2a != size1_2a);
    XCTAssertFalse(size1_2a != size1_2b);
    XCTAssertTrue(size1_2a != size1_3);
    XCTAssertTrue(size1_2a != size2_2);
}

- (void)test_is_equal_float_region {
    auto origin_a1 = ui::float_origin{1.0f, 2.0f};
    auto origin_a2 = ui::float_origin{1.0f, 2.0f};
    auto origin_b = ui::float_origin{3.0f, 4.0f};

    auto size_a1 = ui::float_size{5.0f, 6.0f};
    auto size_a2 = ui::float_size{5.0f, 6.0f};
    auto size_b = ui::float_size{7.0f, 8.0f};

    auto region_a1_a1 = ui::float_region{origin_a1, size_a1};
    auto region_a1_a2 = ui::float_region{origin_a1, size_a2};
    auto region_a2_a1 = ui::float_region{origin_a2, size_a1};
    auto region_a2_a2 = ui::float_region{origin_a2, size_a2};
    auto region_b = ui::float_region{origin_b, size_b};

    XCTAssertTrue(region_a1_a1 == region_a1_a1);
    XCTAssertTrue(region_a1_a1 == region_a1_a2);
    XCTAssertTrue(region_a1_a1 == region_a2_a1);
    XCTAssertTrue(region_a1_a1 == region_a2_a2);
    XCTAssertFalse(region_a1_a1 == region_b);

    XCTAssertFalse(region_a1_a1 != region_a1_a1);
    XCTAssertFalse(region_a1_a1 != region_a1_a2);
    XCTAssertFalse(region_a1_a1 != region_a2_a1);
    XCTAssertFalse(region_a1_a1 != region_a2_a2);
    XCTAssertTrue(region_a1_a1 != region_b);
}

- (void)test_CGPoint_to_float2 {
    CGPoint point{1.0, 2.0};
    auto float2 = to_float2(point);

    XCTAssertEqual(float2.x, 1.0f);
    XCTAssertEqual(float2.y, 2.0f);
}

- (void)test_contains {
#warning todo
}

- (void)test_pivot_to_string {
    XCTAssertEqual(to_string(ui::pivot::center), "center");
    XCTAssertEqual(to_string(ui::pivot::left), "left");
    XCTAssertEqual(to_string(ui::pivot::right), "right");
}

- (void)test_uint_origin_to_string {
    XCTAssertEqual(to_string(ui::uint_origin{1, 2}), "{1, 2}");
}

- (void)test_uint_size_to_string {
    XCTAssertEqual(to_string(ui::uint_size{3, 4}), "{3, 4}");
}

- (void)test_uint_region_to_string {
    XCTAssertEqual(to_string(ui::uint_region{5, 6, 7, 8}), "{{5, 6}, {7, 8}}");
}

- (void)test_float_origin_to_string {
    XCTAssertEqual(to_string(ui::float_origin{1.0f, 2.0f}), "{1.000000, 2.000000}");
}

- (void)test_float_size_to_string {
    XCTAssertEqual(to_string(ui::float_size{3.0f, 4.0f}), "{3.000000, 4.000000}");
}

- (void)test_float_region_to_string {
    XCTAssertEqual(to_string(ui::float_region{5.0f, 6.0f, 7.0f, 8.0f}), "{{5.000000, 6.000000}, {7.000000, 8.000000}}");
}

- (void)test_ostream {
    std::cout << ui::uint_origin{1, 2} << std::endl;
    std::cout << ui::uint_size{3, 4} << std::endl;
    std::cout << ui::uint_region{5, 6, 7, 8} << std::endl;
    std::cout << ui::float_origin{1.0f, 2.0f} << std::endl;
    std::cout << ui::float_size{3.0f, 4.0f} << std::endl;
    std::cout << ui::float_region{5.0f, 6.0f, 7.0f, 8.0f} << std::endl;
}

- (void)test_to_mtl_primitive_type {
    XCTAssertEqual(to_mtl_primitive_type(ui::primitive_type::point), MTLPrimitiveTypePoint);
    XCTAssertEqual(to_mtl_primitive_type(ui::primitive_type::line), MTLPrimitiveTypeLine);
    XCTAssertEqual(to_mtl_primitive_type(ui::primitive_type::line_strip), MTLPrimitiveTypeLineStrip);
    XCTAssertEqual(to_mtl_primitive_type(ui::primitive_type::triangle), MTLPrimitiveTypeTriangle);
    XCTAssertEqual(to_mtl_primitive_type(ui::primitive_type::triangle_strip), MTLPrimitiveTypeTriangleStrip);
}

@end
