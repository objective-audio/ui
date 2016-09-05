//
//  yas_ui_types_tests.mm
//

#import <XCTest/XCTest.h>
#import <sstream>
#import "yas_ui_types.h"

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

- (void)test_is_equal_float2 {
    simd::float2 vector1_2a{1.0f, 2.0f};
    simd::float2 vector1_2b{1.0f, 2.0f};
    simd::float2 vector2_1{2.0f, 1.0f};
    simd::float2 vector1_4{1.0f, 4.0f};
    simd::float2 vector4_2{4.0f, 2.0f};

    XCTAssertTrue(is_equal(vector1_2a, vector1_2a));
    XCTAssertTrue(is_equal(vector1_2a, vector1_2b));

    XCTAssertFalse(is_equal(vector1_2a, vector2_1));
    XCTAssertFalse(is_equal(vector1_2a, vector1_4));
    XCTAssertFalse(is_equal(vector1_2a, vector4_2));
}

- (void)test_is_equal_float3 {
    simd::float3 vector1_2_4a{1.0f, 2.0f, 4.0f};
    simd::float3 vector1_2_4b{1.0f, 2.0f, 4.0f};
    simd::float3 vector4_1_2{4.0f, 1.0f, 2.0f};
    simd::float3 vector1_2_3{1.0f, 2.0f, 3.0f};
    simd::float3 vector1_3_4{1.0f, 3.0f, 4.0f};
    simd::float3 vector3_2_4{3.0f, 2.0f, 4.0f};

    XCTAssertTrue(is_equal(vector1_2_4a, vector1_2_4a));
    XCTAssertTrue(is_equal(vector1_2_4b, vector1_2_4b));

    XCTAssertFalse(is_equal(vector1_2_4a, vector4_1_2));
    XCTAssertFalse(is_equal(vector1_2_4a, vector1_2_3));
    XCTAssertFalse(is_equal(vector1_2_4a, vector1_3_4));
    XCTAssertFalse(is_equal(vector1_2_4a, vector3_2_4));
}

- (void)test_is_equal_float4 {
    simd::float4 vector1_2_4_8a{1.0f, 2.0f, 4.0f, 8.0f};
    simd::float4 vector1_2_4_8b{1.0f, 2.0f, 4.0f, 8.0f};
    simd::float4 vector8_4_1_2{8.0f, 4.0f, 1.0f, 2.0f};
    simd::float4 vector1_2_4_3{1.0f, 2.0f, 4.0f, 3.0f};
    simd::float4 vector1_2_3_8{1.0f, 2.0f, 3.0f, 8.0f};
    simd::float4 vector1_3_4_8{1.0f, 3.0f, 4.0f, 8.0f};
    simd::float4 vector3_2_4_8{3.0f, 2.0f, 4.0f, 8.0f};

    XCTAssertTrue(is_equal(vector1_2_4_8a, vector1_2_4_8a));
    XCTAssertTrue(is_equal(vector1_2_4_8a, vector1_2_4_8b));

    XCTAssertFalse(is_equal(vector1_2_4_8a, vector8_4_1_2));
    XCTAssertFalse(is_equal(vector1_2_4_8a, vector1_2_4_3));
    XCTAssertFalse(is_equal(vector1_2_4_8a, vector1_2_3_8));
    XCTAssertFalse(is_equal(vector1_2_4_8a, vector1_3_4_8));
    XCTAssertFalse(is_equal(vector1_2_4_8a, vector3_2_4_8));
}

- (void)test_is_equal_float4x4 {
    simd::float4x4 matrix_a1{simd::float4{1.0f, 2.0f, 3.0f, 4.0f}, simd::float4{5.0f, 6.0f, 7.0f, 8.0f},
                             simd::float4{9.0f, 10.0f, 11.0f, 12.0f}, simd::float4{13.0f, 14.0f, 15.0f, 16.0f}};
    simd::float4x4 matrix_a2{simd::float4{1.0f, 2.0f, 3.0f, 4.0f}, simd::float4{5.0f, 6.0f, 7.0f, 8.0f},
                             simd::float4{9.0f, 10.0f, 11.0f, 12.0f}, simd::float4{13.0f, 14.0f, 15.0f, 16.0f}};
    simd::float4x4 matrix_b{simd::float4{5.0f, 6.0f, 7.0f, 8.0f}, simd::float4{9.0f, 10.0f, 11.0f, 12.0f},
                            simd::float4{13.0f, 14.0f, 15.0f, 16.0f}, simd::float4{1.0f, 2.0f, 3.0f, 4.0f}};
    simd::float4x4 matrix_c{0};

    XCTAssertTrue(is_equal(matrix_a1, matrix_a1));
    XCTAssertTrue(is_equal(matrix_a1, matrix_a2));

    XCTAssertFalse(is_equal(matrix_a1, matrix_b));
    XCTAssertFalse(is_equal(matrix_a1, matrix_c));
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

- (void)test_is_equal_point {
    auto origin1_2a = ui::point{1.0f, 2.0f};
    auto origin1_2b = ui::point{1.0f, 2.0f};
    auto origin1_3 = ui::point{1.0f, 3.0f};
    auto origin2_2 = ui::point{2, 2};

    XCTAssertTrue(origin1_2a == origin1_2a);
    XCTAssertTrue(origin1_2a == origin1_2b);
    XCTAssertFalse(origin1_2a == origin1_3);
    XCTAssertFalse(origin1_2a == origin2_2);

    XCTAssertFalse(origin1_2a != origin1_2a);
    XCTAssertFalse(origin1_2a != origin1_2b);
    XCTAssertTrue(origin1_2a != origin1_3);
    XCTAssertTrue(origin1_2a != origin2_2);
}

- (void)test_is_equal_size {
    auto size1_2a = ui::size{1.0f, 2.0f};
    auto size1_2b = ui::size{1.0f, 2.0f};
    auto size1_3 = ui::size{1.0f, 3.0f};
    auto size2_2 = ui::size{2.0f, 2.0f};

    XCTAssertTrue(size1_2a == size1_2a);
    XCTAssertTrue(size1_2a == size1_2b);
    XCTAssertFalse(size1_2a == size1_3);
    XCTAssertFalse(size1_2a == size2_2);

    XCTAssertFalse(size1_2a != size1_2a);
    XCTAssertFalse(size1_2a != size1_2b);
    XCTAssertTrue(size1_2a != size1_3);
    XCTAssertTrue(size1_2a != size2_2);
}

- (void)test_is_equal_region {
    auto origin_a1 = ui::point{1.0f, 2.0f};
    auto origin_a2 = ui::point{1.0f, 2.0f};
    auto origin_b = ui::point{3.0f, 4.0f};

    auto size_a1 = ui::size{5.0f, 6.0f};
    auto size_a2 = ui::size{5.0f, 6.0f};
    auto size_b = ui::size{7.0f, 8.0f};

    auto region_a1_a1 = ui::region{origin_a1, size_a1};
    auto region_a1_a2 = ui::region{origin_a1, size_a2};
    auto region_a2_a1 = ui::region{origin_a2, size_a1};
    auto region_a2_a2 = ui::region{origin_a2, size_a2};
    auto region_b = ui::region{origin_b, size_b};

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
    ui::region region = {.origin = {0.0f, -1.0f}, .size = {1.0f, 2.0f}};

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

- (void)test_region_to_string {
    XCTAssertEqual(to_string(ui::region{.origin = {5.0f, 6.0f}, .size = {7.0f, 8.0f}}),
                   "{{5.000000, 6.000000}, {7.000000, 8.000000}}");
}

- (void)test_point_to_string {
    XCTAssertEqual(to_string(ui::point{1.0f, 2.0f}), "{1.000000, 2.000000}");
}

- (void)test_size_to_string {
    XCTAssertEqual(to_string(ui::size{1.0f, 2.0f}), "{1.000000, 2.000000}");
}

- (void)test_color_to_string {
    XCTAssertEqual(to_string(ui::color{1.0f, 2.0f, 3.0f}), "{1.000000, 2.000000, 3.000000}");
}

- (void)test_simd_float2_to_string {
    XCTAssertEqual(to_string(simd::float2{1.0f, 2.0f}), "{1.000000, 2.000000}");
}

- (void)test_simd_float3_to_string {
    XCTAssertEqual(to_string(simd::float3{1.0f, 2.0f, 3.0f}), "{1.000000, 2.000000, 3.000000}");
}

- (void)test_simd_float4_to_string {
    XCTAssertEqual(to_string(simd::float4{1.0f, 2.0f, 3.0f, 4.0f}), "{1.000000, 2.000000, 3.000000, 4.000000}");
}

- (void)test_simd_float4x4_to_string {
    simd::float4x4 matrix{simd::float4{1.0f, 2.0f, 3.0f, 4.0f}, simd::float4{5.0f, 6.0f, 7.0f, 8.0f},
                          simd::float4{9.0f, 10.0f, 11.0f, 12.0f}, simd::float4{13.0f, 14.0f, 15.0f, 16.0f}};
    XCTAssertEqual(to_string(matrix),
                   "{{1.000000, 2.000000, 3.000000, 4.000000}, {5.000000, 6.000000, 7.000000, 8.000000}, {9.000000, "
                   "10.000000, 11.000000, 12.000000}, {13.000000, 14.000000, 15.000000, 16.000000}}");
}

- (void)test_uint_origin_ostream {
    std::ostringstream stream;
    stream << ui::uint_origin{1, 2};
    XCTAssertEqual(stream.str(), "{1, 2}");
}

- (void)test_uint_region_ostream {
    std::ostringstream stream;
    stream << ui::uint_region{5, 6, 7, 8};
    XCTAssertEqual(stream.str(), "{{5, 6}, {7, 8}}");
}

- (void)test_uint_size_ostream {
    std::ostringstream stream;
    stream << ui::uint_size{3, 4};
    XCTAssertEqual(stream.str(), "{3, 4}");
}

- (void)test_region_ostream {
    std::ostringstream stream;
    stream << ui::region{.origin = {5.0f, 6.0f}, .size = {7.0f, 8.0f}};
    XCTAssertEqual(stream.str(), "{{5.000000, 6.000000}, {7.000000, 8.000000}}");
}

- (void)test_point_ostream {
    std::ostringstream stream;
    stream << ui::point{9.0f, 10.0f};
    XCTAssertEqual(stream.str(), "{9.000000, 10.000000}");
}

- (void)test_size_ostream {
    std::ostringstream stream;
    stream << ui::size{11.0f, 12.0f};
    XCTAssertEqual(stream.str(), "{11.000000, 12.000000}");
}

- (void)test_color_ostream {
    std::ostringstream stream;
    stream << ui::color{13.0f, 14.0f, 15.0f};
    XCTAssertEqual(stream.str(), "{13.000000, 14.000000, 15.000000}");
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
    ui::point p{.v = simd::float2{3.0f, 4.0f}};

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
    ui::color c = {.v = 1.0f};

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

- (void)test_create_region_with_float4 {
    ui::region region{.v = simd::float4{1.0f, 2.0f, 3.0f, 4.0f}};

    XCTAssertEqual(region.origin.x, 1.0f);
    XCTAssertEqual(region.origin.y, 2.0f);
    XCTAssertEqual(region.size.width, 3.0f);
    XCTAssertEqual(region.size.height, 4.0f);
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

- (void)test_uint_region_getter {
    ui::uint_region region;

    region = {.origin = {0, 1}, .size = {2, 3}};

    XCTAssertEqual(region.left(), 0);
    XCTAssertEqual(region.right(), 2);
    XCTAssertEqual(region.bottom(), 1);
    XCTAssertEqual(region.top(), 4);
}

- (void)test_uint_range_getter {
    ui::uint_range range;

    range = {.location = 1, .length = 2};

    XCTAssertEqual(range.min(), 1);
    XCTAssertEqual(range.max(), 3);
}

- (void)test_region_getter {
    ui::region region;

    region = {.origin = {0.0f, 1.0f}, .size = {2.0f, 3.0f}};

    XCTAssertEqual(region.left(), 0.0f);
    XCTAssertEqual(region.right(), 2.0f);
    XCTAssertEqual(region.bottom(), 1.0f);
    XCTAssertEqual(region.top(), 4.0f);

    region = {.origin = {4.0f, 5.0f}, .size = {-7.0f, -6.0f}};

    XCTAssertEqual(region.left(), -3.0f);
    XCTAssertEqual(region.right(), 4.0f);
    XCTAssertEqual(region.bottom(), -1.0f);
    XCTAssertEqual(region.top(), 5.0f);
}

- (void)test_range_getter {
    ui::range range;

    range = {.location = 1.0f, .length = 2.0f};

    XCTAssertEqual(range.min(), 1.0f);
    XCTAssertEqual(range.max(), 3.0f);

    range = {.location = 3.0f, .length = -1.0f};

    XCTAssertEqual(range.min(), 2.0f);
    XCTAssertEqual(range.max(), 3.0f);
}

@end
