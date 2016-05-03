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
    ui::float_region region = {0.0f, -1.0f, 1.0f, 2.0f};

    XCTAssertTrue(contains(region, {0.0f, 0.0f}));
    XCTAssertTrue(contains(region, {0.0f, -1.0f}));
    XCTAssertTrue(contains(region, {0.999f, 0.0f}));
    XCTAssertTrue(contains(region, {0.0f, 0.999f}));

    XCTAssertFalse(contains(region, {-0.0001f, 0.0f}));
    XCTAssertFalse(contains(region, {0.0f, -1.001f}));
    XCTAssertFalse(contains(region, {1.0f, 0.0f}));
    XCTAssertFalse(contains(region, {0.0f, 1.0f}));
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

- (void)test_create_point {
    ui::point p;

    XCTAssertEqual(p.x, 0.0f);
    XCTAssertEqual(p.y, 0.0f);
}

- (void)test_create_point_with_params {
    ui::point p{1.0f, 2.0f};

    XCTAssertEqual(p.x, 1.0f);
    XCTAssertEqual(p.y, 2.0f);
}

- (void)test_create_point_with_float2 {
    ui::point p{simd::float2{3.0f, 4.0f}};

    XCTAssertEqual(p.x, 3.0f);
    XCTAssertEqual(p.y, 4.0f);
}

- (void)test_create_size {
    ui::size s;

    XCTAssertEqual(s.width, 0.0f);
    XCTAssertEqual(s.height, 0.0f);
}

- (void)test_create_size_with_params {
    ui::size s{1.0f, 2.0f};

    XCTAssertEqual(s.width, 1.0f);
    XCTAssertEqual(s.height, 2.0f);
}

- (void)test_create_color {
    ui::color c;

    XCTAssertEqual(c.red, 1.0f);
    XCTAssertEqual(c.green, 1.0f);
    XCTAssertEqual(c.blue, 1.0f);
}

- (void)test_create_color_with_params {
    ui::color c{1.0f, 2.0f, 3.0f};

    XCTAssertEqual(c.red, 1.0f);
    XCTAssertEqual(c.green, 2.0f);
    XCTAssertEqual(c.blue, 3.0f);
}

- (void)test_is_equal_points {
    ui::point p1{1.0f, 2.0f};
    ui::point p2{1.0f, 2.0f};
    ui::point p3{1.1f, 2.0f};
    ui::point p4{1.0f, 2.1f};
    ui::point p5{1.1f, 2.1f};
    ui::point pz1{0.0f, 0.0f};
    ui::point pz2{0.0f, 0.0f};

    XCTAssertTrue(p1 == p2);
    XCTAssertFalse(p1 == p3);
    XCTAssertFalse(p1 == p4);
    XCTAssertFalse(p1 == p5);
    XCTAssertTrue(pz1 == pz2);

    XCTAssertFalse(p1 != p2);
    XCTAssertTrue(p1 != p3);
    XCTAssertTrue(p1 != p4);
    XCTAssertTrue(p1 != p5);
    XCTAssertFalse(pz1 != pz2);
}

- (void)test_is_equal_sizes {
    ui::size s1{1.0f, 2.0f};
    ui::size s2{1.0f, 2.0f};
    ui::size s3{1.1f, 2.0f};
    ui::size s4{1.0f, 2.1f};
    ui::size s5{1.1f, 2.1f};
    ui::size sz1{0.0f, 0.0f};
    ui::size sz2{0.0f, 0.0f};

    XCTAssertTrue(s1 == s2);
    XCTAssertFalse(s1 == s3);
    XCTAssertFalse(s1 == s4);
    XCTAssertFalse(s1 == s5);
    XCTAssertTrue(sz1 == sz2);

    XCTAssertFalse(s1 != s2);
    XCTAssertTrue(s1 != s3);
    XCTAssertTrue(s1 != s4);
    XCTAssertTrue(s1 != s5);
    XCTAssertFalse(sz1 != sz2);
}

- (void)test_is_equal_colors {
    ui::color c1{1.0f, 2.0f, 3.0f};
    ui::color c2{1.0f, 2.0f, 3.0f};
    ui::color c3{1.1f, 2.0f, 3.0f};
    ui::color c4{1.0f, 2.1f, 3.0f};
    ui::color c5{1.0f, 2.0f, 3.1f};
    ui::color c6{1.1f, 2.1f, 3.1f};
    ui::color cz1{0.0f, 0.0f, 0.0f};
    ui::color cz2{0.0f, 0.0f, 0.0f};

    XCTAssertTrue(c1 == c2);
    XCTAssertFalse(c1 == c3);
    XCTAssertFalse(c1 == c4);
    XCTAssertFalse(c1 == c5);
    XCTAssertFalse(c1 == c6);
    XCTAssertTrue(cz1 == cz2);

    XCTAssertFalse(c1 != c2);
    XCTAssertTrue(c1 != c3);
    XCTAssertTrue(c1 != c4);
    XCTAssertTrue(c1 != c5);
    XCTAssertTrue(c1 != c6);
    XCTAssertFalse(cz1 != cz2);
}

@end
