//
//  yas_ui_types_tests.mm
//

#import <XCTest/XCTest.h>
#import <ui/ui.h>
#import <sstream>

using namespace yas;
using namespace yas::ui;

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
    simd::float4x4 matrix_c{simd::float4{0.0f, 0.0f, 0.0f, 0.0f}, simd::float4{0.0f, 0.0f, 0.0f, 0.0f},
                            simd::float4{0.0f, 0.0f, 0.0f, 0.0f}, simd::float4{0.0f, 0.0f, 0.0f, 0.0f}};

    XCTAssertTrue(is_equal(matrix_a1, matrix_a1));
    XCTAssertTrue(is_equal(matrix_a1, matrix_a2));

    XCTAssertFalse(is_equal(matrix_a1, matrix_b));
    XCTAssertFalse(is_equal(matrix_a1, matrix_c));
}

- (void)test_is_equal_uint_point {
    auto origin1_2a = uint_point{1, 2};
    auto origin1_2b = uint_point{1, 2};
    auto origin1_3 = uint_point{1, 3};
    auto origin2_2 = uint_point{2, 2};

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
    auto size1_2a = uint_size{1, 2};
    auto size1_2b = uint_size{1, 2};
    auto size1_3 = uint_size{1, 3};
    auto size2_2 = uint_size{2, 2};

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
    auto origin_a1 = uint_point{1, 2};
    auto origin_a2 = uint_point{1, 2};
    auto origin_b = uint_point{3, 4};

    auto size_a1 = uint_size{5, 6};
    auto size_a2 = uint_size{5, 6};
    auto size_b = uint_size{7, 8};

    auto region_a1_a1 = uint_region{origin_a1, size_a1};
    auto region_a1_a2 = uint_region{origin_a1, size_a2};
    auto region_a2_a1 = uint_region{origin_a2, size_a1};
    auto region_a2_a2 = uint_region{origin_a2, size_a2};
    auto region_b = uint_region{origin_b, size_b};

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

- (void)test_is_equal_uint_range {
    auto range1_2a = uint_range{1, 2};
    auto range1_2b = uint_range{1, 2};
    auto range1_3 = uint_range{1, 3};
    auto range2_2 = uint_range{2, 2};

    XCTAssertTrue(range1_2a == range1_2a);
    XCTAssertTrue(range1_2a == range1_2b);
    XCTAssertFalse(range1_2a == range1_3);
    XCTAssertFalse(range1_2a == range2_2);

    XCTAssertFalse(range1_2a != range1_2a);
    XCTAssertFalse(range1_2a != range1_2b);
    XCTAssertTrue(range1_2a != range1_3);
    XCTAssertTrue(range1_2a != range2_2);
}

- (void)test_is_equal_point {
    auto origin1_2a = point{1.0f, 2.0f};
    auto origin1_2b = point{1.0f, 2.0f};
    auto origin1_3 = point{1.0f, 3.0f};
    auto origin2_2 = point{2, 2};

    XCTAssertTrue(origin1_2a == origin1_2a);
    XCTAssertTrue(origin1_2a == origin1_2b);
    XCTAssertFalse(origin1_2a == origin1_3);
    XCTAssertFalse(origin1_2a == origin2_2);

    XCTAssertFalse(origin1_2a != origin1_2a);
    XCTAssertFalse(origin1_2a != origin1_2b);
    XCTAssertTrue(origin1_2a != origin1_3);
    XCTAssertTrue(origin1_2a != origin2_2);
}

- (void)test_add_points {
    point point_1{1.0f, 2.0f};
    point point_2{3.0f, 4.0f};

    auto const point = point_1 + point_2;

    XCTAssertEqualWithAccuracy(point.x, 4.0f, 0.001f);
    XCTAssertEqualWithAccuracy(point.y, 6.0f, 0.001f);
}

- (void)test_subtract_points {
    point point_1{4.0f, 3.0f};
    point point_2{1.0f, 2.0f};

    auto const point = point_1 - point_2;

    XCTAssertEqualWithAccuracy(point.x, 3.0f, 0.001f);
    XCTAssertEqualWithAccuracy(point.y, 1.0f, 0.001f);
}

- (void)test_add_point_itself {
    point point_1{1.0f, 2.0f};
    point point_2{3.0f, 4.0f};

    point_1 += point_2;

    XCTAssertEqualWithAccuracy(point_1.x, 4.0f, 0.001f);
    XCTAssertEqualWithAccuracy(point_1.y, 6.0f, 0.001f);
}

- (void)test_minus_point_itself {
    point point_1{4.0f, 3.0f};
    point point_2{1.0f, 2.0f};

    point_1 -= point_2;

    XCTAssertEqualWithAccuracy(point_1.x, 3.0f, 0.001f);
    XCTAssertEqualWithAccuracy(point_1.y, 1.0f, 0.001f);
}

- (void)test_is_equal_size {
    auto size1_2a = size{1.0f, 2.0f};
    auto size1_2b = size{1.0f, 2.0f};
    auto size1_3 = size{1.0f, 3.0f};
    auto size2_2 = size{2.0f, 2.0f};

    XCTAssertTrue(size1_2a == size1_2a);
    XCTAssertTrue(size1_2a == size1_2b);
    XCTAssertFalse(size1_2a == size1_3);
    XCTAssertFalse(size1_2a == size2_2);

    XCTAssertFalse(size1_2a != size1_2a);
    XCTAssertFalse(size1_2a != size1_2b);
    XCTAssertTrue(size1_2a != size1_3);
    XCTAssertTrue(size1_2a != size2_2);
}

- (void)test_is_equal_insets {
    auto insets_a1 = insets{1.0f, 2.0f, 3.0f, 4.0f};
    auto insets_a2 = insets{1.0f, 2.0f, 3.0f, 4.0f};
    auto insets_diff_left = insets{1.5f, 2.0f, 3.0f, 4.0f};
    auto insets_diff_right = insets{1.0f, 2.5f, 3.0f, 4.0f};
    auto insets_diff_bottom = insets{1.0f, 2.0f, 3.5f, 4.0f};
    auto insets_diff_top = insets{1.0f, 2.0f, 3.0f, 4.5f};

    XCTAssertTrue(insets_a1 == insets_a1);
    XCTAssertTrue(insets_a1 == insets_a2);

    XCTAssertFalse(insets_a1 == insets_diff_left);
    XCTAssertFalse(insets_a1 == insets_diff_right);
    XCTAssertFalse(insets_a1 == insets_diff_bottom);
    XCTAssertFalse(insets_a1 == insets_diff_top);
}

- (void)test_is_equal_region {
    auto origin_a1 = point{1.0f, 2.0f};
    auto origin_a2 = point{1.0f, 2.0f};
    auto origin_b = point{3.0f, 4.0f};

    auto size_a1 = size{5.0f, 6.0f};
    auto size_a2 = size{5.0f, 6.0f};
    auto size_b = size{7.0f, 8.0f};

    auto region_a1_a1 = region{origin_a1, size_a1};
    auto region_a1_a2 = region{origin_a1, size_a2};
    auto region_a2_a1 = region{origin_a2, size_a1};
    auto region_a2_a2 = region{origin_a2, size_a2};
    auto region_b = region{origin_b, size_b};

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
    region region = {.origin = {0.0f, -1.0f}, .size = {1.0f, 2.0f}};

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
    XCTAssertEqual(to_string(pivot::center), "center");
    XCTAssertEqual(to_string(pivot::left), "left");
    XCTAssertEqual(to_string(pivot::right), "right");
}

- (void)test_uint_point_to_string {
    XCTAssertEqual(to_string(uint_point{1, 2}), "{1, 2}");
}

- (void)test_uint_size_to_string {
    XCTAssertEqual(to_string(uint_size{3, 4}), "{3, 4}");
}

- (void)test_uint_region_to_string {
    XCTAssertEqual(to_string(uint_region{5, 6, 7, 8}), "{{5, 6}, {7, 8}}");
}

- (void)test_insets_to_string {
    XCTAssertEqual(to_string(insets{5.0f, 6.0f, 7.0f, 8.0f}), "{5.000000, 6.000000, 7.000000, 8.000000}");
}

- (void)test_region_to_string {
    XCTAssertEqual(to_string(region{.origin = {5.0f, 6.0f}, .size = {7.0f, 8.0f}}),
                   "{{5.000000, 6.000000}, {7.000000, 8.000000}}");
}

- (void)test_point_to_string {
    XCTAssertEqual(to_string(point{1.0f, 2.0f}), "{1.000000, 2.000000}");
}

- (void)test_size_to_string {
    XCTAssertEqual(to_string(size{1.0f, 2.0f}), "{1.000000, 2.000000}");
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

- (void)test_uint_point_ostream {
    std::ostringstream stream;
    stream << uint_point{1, 2};
    XCTAssertEqual(stream.str(), "{1, 2}");
}

- (void)test_uint_region_ostream {
    std::ostringstream stream;
    stream << uint_region{5, 6, 7, 8};
    XCTAssertEqual(stream.str(), "{{5, 6}, {7, 8}}");
}

- (void)test_uint_size_ostream {
    std::ostringstream stream;
    stream << uint_size{3, 4};
    XCTAssertEqual(stream.str(), "{3, 4}");
}

- (void)test_insets_ostream {
    std::ostringstream stream;
    stream << insets{5.0f, 6.0f, 7.0f, 8.0f};
    XCTAssertEqual(stream.str(), "{5.000000, 6.000000, 7.000000, 8.000000}");
}

- (void)test_region_ostream {
    std::ostringstream stream;
    stream << region{.origin = {5.0f, 6.0f}, .size = {7.0f, 8.0f}};
    XCTAssertEqual(stream.str(), "{{5.000000, 6.000000}, {7.000000, 8.000000}}");
}

- (void)test_point_ostream {
    std::ostringstream stream;
    stream << point{9.0f, 10.0f};
    XCTAssertEqual(stream.str(), "{9.000000, 10.000000}");
}

- (void)test_size_ostream {
    std::ostringstream stream;
    stream << size{11.0f, 12.0f};
    XCTAssertEqual(stream.str(), "{11.000000, 12.000000}");
}

- (void)test_create_point {
    point p;

    XCTAssertEqual(p.x, 0.0f);
    XCTAssertEqual(p.y, 0.0f);
}

- (void)test_create_point_with_params {
    point p{1.0f, 2.0f};

    XCTAssertEqual(p.x, 1.0f);
    XCTAssertEqual(p.y, 2.0f);
}

- (void)test_create_point_with_float2 {
    point p{.v = simd::float2{3.0f, 4.0f}};

    XCTAssertEqual(p.x, 3.0f);
    XCTAssertEqual(p.y, 4.0f);
}

- (void)test_create_size {
    size s;

    XCTAssertEqual(s.width, 0.0f);
    XCTAssertEqual(s.height, 0.0f);
}

- (void)test_create_size_with_params {
    size s{1.0f, 2.0f};

    XCTAssertEqual(s.width, 1.0f);
    XCTAssertEqual(s.height, 2.0f);
}

- (void)test_create_region_with_float4 {
    region region{.v = simd::float4{1.0f, 2.0f, 3.0f, 4.0f}};

    XCTAssertEqual(region.origin.x, 1.0f);
    XCTAssertEqual(region.origin.y, 2.0f);
    XCTAssertEqual(region.size.width, 3.0f);
    XCTAssertEqual(region.size.height, 4.0f);
}

- (void)test_is_equal_points {
    point p1{1.0f, 2.0f};
    point p2{1.0f, 2.0f};
    point p3{1.1f, 2.0f};
    point p4{1.0f, 2.1f};
    point p5{1.1f, 2.1f};
    point pz1{0.0f, 0.0f};
    point pz2{0.0f, 0.0f};

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
    size s1{1.0f, 2.0f};
    size s2{1.0f, 2.0f};
    size s3{1.1f, 2.0f};
    size s4{1.0f, 2.1f};
    size s5{1.1f, 2.1f};
    size sz1{0.0f, 0.0f};
    size sz2{0.0f, 0.0f};

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

- (void)test_is_equal_ranges {
    range r1{1.0f, 2.0f};
    range r2{1.0f, 2.0f};
    range r3{1.1f, 2.0f};
    range r4{1.0f, 2.1f};
    range r5{1.1f, 2.1f};
    range rz1{0.0f, 0.0f};
    range rz2{0.0f, 0.0f};

    XCTAssertTrue(r1 == r2);
    XCTAssertFalse(r1 == r3);
    XCTAssertFalse(r1 == r4);
    XCTAssertFalse(r1 == r5);
    XCTAssertTrue(rz1 == rz2);

    XCTAssertFalse(r1 != r2);
    XCTAssertTrue(r1 != r3);
    XCTAssertTrue(r1 != r4);
    XCTAssertTrue(r1 != r5);
    XCTAssertFalse(rz1 != rz2);
}

- (void)test_uint_region_getter {
    uint_region region;

    region = {.origin = {0, 1}, .size = {2, 3}};

    XCTAssertEqual(region.left(), 0);
    XCTAssertEqual(region.right(), 2);
    XCTAssertEqual(region.bottom(), 1);
    XCTAssertEqual(region.top(), 4);
}

- (void)test_uint_range_getter {
    uint_range range;

    range = {.location = 1, .length = 2};

    XCTAssertEqual(range.min(), 1);
    XCTAssertEqual(range.max(), 3);
}

- (void)test_region_getter {
    region region;

    region = {.origin = {0.0f, 1.0f}, .size = {2.0f, 3.0f}};

    XCTAssertEqual(region.left(), 0.0f);
    XCTAssertEqual(region.right(), 2.0f);
    XCTAssertEqual(region.bottom(), 1.0f);
    XCTAssertEqual(region.top(), 4.0f);
    XCTAssertEqualWithAccuracy(region.insets().left, 0.0f, 0.001f);
    XCTAssertEqualWithAccuracy(region.insets().right, 2.0f, 0.001f);
    XCTAssertEqualWithAccuracy(region.insets().bottom, 1.0f, 0.001f);
    XCTAssertEqualWithAccuracy(region.insets().top, 4.0f, 0.001f);
    XCTAssertEqualWithAccuracy(region.center().x, 1.0f, 0.001f);
    XCTAssertEqualWithAccuracy(region.center().y, 2.5f, 0.001f);

    region = {.origin = {4.0f, 5.0f}, .size = {-7.0f, -6.0f}};

    XCTAssertEqual(region.left(), -3.0f);
    XCTAssertEqual(region.right(), 4.0f);
    XCTAssertEqual(region.bottom(), -1.0f);
    XCTAssertEqual(region.top(), 5.0f);
}

- (void)test_range_getter {
    range range;

    range = {.location = 1.0f, .length = 2.0f};

    XCTAssertEqual(range.min(), 1.0f);
    XCTAssertEqual(range.max(), 3.0f);

    range = {.location = 3.0f, .length = -1.0f};

    XCTAssertEqual(range.min(), 2.0f);
    XCTAssertEqual(range.max(), 3.0f);
}

- (void)test_uint_point_zero {
    XCTAssertEqual(uint_point::zero().x, 0);
    XCTAssertEqual(uint_point::zero().y, 0);
}

- (void)test_uint_size_zero {
    XCTAssertEqual(uint_size::zero().width, 0);
    XCTAssertEqual(uint_size::zero().height, 0);
}

- (void)test_uint_region_zero {
    XCTAssertEqual(uint_region::zero().origin.x, 0);
    XCTAssertEqual(uint_region::zero().origin.y, 0);
    XCTAssertEqual(uint_region::zero().size.width, 0);
    XCTAssertEqual(uint_region::zero().size.height, 0);
}

- (void)test_uint_range_zero {
    XCTAssertEqual(uint_range::zero().location, 0);
    XCTAssertEqual(uint_range::zero().length, 0);
}

- (void)test_point_zero {
    XCTAssertEqual(point::zero().x, 0.0f);
    XCTAssertEqual(point::zero().y, 0.0f);
}

- (void)test_size_zero {
    XCTAssertEqual(size::zero().width, 0.0f);
    XCTAssertEqual(size::zero().height, 0.0f);
}

- (void)test_range_zero {
    XCTAssertEqual(range::zero().location, 0.0f);
    XCTAssertEqual(range::zero().length, 0.0f);
}

- (void)test_insets_zero {
    XCTAssertEqual(insets::zero().left, 0.0f);
    XCTAssertEqual(insets::zero().right, 0.0f);
    XCTAssertEqual(insets::zero().bottom, 0.0f);
    XCTAssertEqual(insets::zero().top, 0.0f);
}

- (void)test_region_zero {
    XCTAssertEqual(region::zero().origin.x, 0.0f);
    XCTAssertEqual(region::zero().origin.y, 0.0f);
    XCTAssertEqual(region::zero().size.width, 0.0f);
    XCTAssertEqual(region::zero().size.height, 0.0f);
}

- (void)test_region_zero_centered {
    auto region = region::zero_centered(size{.width = 2.0f, .height = 4.0f});

    XCTAssertEqual(region.origin.x, -1.0f);
    XCTAssertEqual(region.origin.y, -2.0f);
    XCTAssertEqual(region.size.width, 2.0f);
    XCTAssertEqual(region.size.height, 4.0f);
}

- (void)test_region_add_inset {
    region const source{.origin = {1.0f, 2.0f}, .size = {3.0f, 4.0f}};
    insets const insets{.left = -1.0f, .right = 2.0f, .bottom = -3.0f, .top = 4.0f};

    region const added = source + insets;
    region const expected = region{.origin = {.x = 0.0f, .y = -1.0f}, .size = {.width = 6.0f, .height = 11.0f}};

    XCTAssertTrue(added == expected);
}

- (void)test_region_subtract_inset {
    region const source{.origin = {1.0f, 2.0f}, .size = {3.0f, 4.0f}};
    insets const insets{.left = -1.0f, .right = 2.0f, .bottom = -3.0f, .top = 4.0f};

    region const subtracted = source - insets;
    region const expected = region{.origin = {.x = 2.0f, .y = 5.0f}, .size = {.width = 0.0f, .height = -3.0f}};

    XCTAssertTrue(subtracted == expected);
}

- (void)test_region_add_assign_inset {
    region region{.origin = {1.0f, 2.0f}, .size = {3.0f, 4.0f}};
    insets const insets{.left = -1.0f, .right = 2.0f, .bottom = -3.0f, .top = 4.0f};

    region += insets;
    ui::region const expected{.origin = {.x = 0.0f, .y = -1.0f}, .size = {.width = 6.0f, .height = 11.0f}};

    XCTAssertTrue(region == expected);
}

- (void)test_region_subtract_assign_inset {
    region region{.origin = {1.0f, 2.0f}, .size = {3.0f, 4.0f}};
    insets const insets{.left = -1.0f, .right = 2.0f, .bottom = -3.0f, .top = 4.0f};

    region -= insets;
    ui::region const expected{.origin = {.x = 2.0f, .y = 5.0f}, .size = {.width = 0.0f, .height = -3.0f}};

    XCTAssertTrue(region == expected);
}

- (void)test_uint_point_to_point {
    XCTAssertTrue(to_point(uint_point{.x = 1, .y = 2}) == (point{.x = 1.0f, .y = 2.0f}));
}

- (void)test_uint_size_to_size {
    XCTAssertTrue(to_size(uint_size{.width = 4, .height = 8}) == (size{.width = 4.0f, .height = 8.0f}));
}

- (void)test_uint_range_to_range {
    XCTAssertTrue(to_range(uint_range{.location = 2, .length = 4}) == (range{.location = 2.0f, .length = 4.0f}));
}

- (void)test_uint_region_to_region {
    XCTAssertTrue(to_region(uint_region{.origin = {.x = 1, .y = 2}, .size = {.width = 4, .height = 8}}) ==
                  (region{.origin = {.x = 1.0f, .y = 2.0f}, .size = {.width = 4.0f, .height = 8.0f}}));
}

- (void)test_range_combined {
    XCTAssertTrue((range{0, 1}.combined({2, 1})) == (range{0, 3}));
    XCTAssertTrue((range{-1, 2}.combined({0, 3})) == (range{-1, 4}));
    XCTAssertTrue(range::zero().combined(range::zero()) == range::zero());
}

- (void)test_region_combined {
    XCTAssertTrue((region{.origin = {0, 1}, .size = {2, 3}}.combined({.origin = {4, 5}, .size = {6, 7}})) ==
                  (region{.origin = {0, 1}, .size = {10, 11}}));
}

- (void)test_range_intersected {
    XCTAssertTrue((range{0, 1}.intersected({0, 1})) == (range{0, 1}));
    XCTAssertTrue((range{0, 1}.intersected({1, 1})) == (range{1, 0}));
    XCTAssertTrue((range{0, 2}.intersected({1, 2})) == (range{1, 1}));
    XCTAssertFalse((range{0, 1}.intersected({2, 1})).has_value());
}

- (void)test_region_intersected {
    XCTAssertTrue((region{.origin = {0, 1}, .size = {2, 3}}.intersected({.origin = {1, 2}, .size = {4, 5}})) ==
                  (region{.origin = {1, 2}, .size = {1, 2}}));
}

@end
