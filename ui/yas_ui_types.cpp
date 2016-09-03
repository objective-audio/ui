//
//  yas_ui_types.cpp
//

#include "yas_ui_types.h"

using namespace yas;

#pragma mark - ui::uint_region

uint32_t ui::uint_region::left() const {
    return std::min(origin.x, origin.x + size.width);
}

uint32_t ui::uint_region::right() const {
    return std::max(origin.x, origin.x + size.width);
}

uint32_t ui::uint_region::bottom() const {
    return std::min(origin.y, origin.y + size.height);
}

uint32_t ui::uint_region::top() const {
    return std::max(origin.y, origin.y + size.height);
}

#pragma mark - ui:uint_range

uint32_t ui::uint_range::min() const {
    return std::min(location, location + length);
}

uint32_t ui::uint_range::max() const {
    return std::max(location, location + length);
}

#pragma mark - ui::float_range

float ui::float_range::min() const {
    return std::min(location, location + length);
}

float ui::float_range::max() const {
    return std::max(location, location + length);
}

#pragma mark - ui::region

ui::float_range ui::region::horizontal_range() const {
    return ui::float_range{.location = origin.x, .length = size.width};
}

ui::float_range ui::region::vertical_range() const {
    return ui::float_range{.location = origin.y, .length = size.height};
}

float ui::region::left() const {
    return std::min(origin.x, origin.x + size.width);
}

float ui::region::right() const {
    return std::max(origin.x, origin.x + size.width);
}

float ui::region::bottom() const {
    return std::min(origin.y, origin.y + size.height);
}

float ui::region::top() const {
    return std::max(origin.y, origin.y + size.height);
}

#pragma mark - ui::point

ui::point::point() {
}

ui::point::point(float const x, float const y) : x(x), y(y) {
}

ui::point::point(simd::float2 v) : v(std::move(v)) {
}

bool ui::point::operator==(point const &rhs) const {
    return x == rhs.x && y == rhs.y;
}

bool ui::point::operator!=(point const &rhs) const {
    return x != rhs.x || y != rhs.y;
}

ui::point::operator bool() const {
    return x != 0 || y != 0;
}

#pragma mark - ui::size

ui::size::size() {
}

ui::size::size(float const w, float const h) : width(w), height(h) {
}

ui::size::size(simd::float2 v) : v(std::move(v)) {
}

bool ui::size::operator==(size const &rhs) const {
    return width == rhs.width && height == rhs.height;
}

bool ui::size::operator!=(size const &rhs) const {
    return width != rhs.width || height != rhs.height;
}

ui::size::operator bool() const {
    return width != 0 || height != 0;
}

#pragma mark -

ui::color::color() {
}

ui::color::color(float const r, float const g, float const b) : red(r), green(g), blue(b) {
}

ui::color::color(simd::float3 v) : v(std::move(v)) {
}

bool ui::color::operator==(color const &rhs) const {
    return red == rhs.red && green == rhs.green && blue == rhs.blue;
}

bool ui::color::operator!=(color const &rhs) const {
    return red != rhs.red || green != rhs.green || blue != rhs.blue;
}

ui::color::operator bool() const {
    return red != 0 || green != 0 || blue != 0;
}

#pragma mark -

simd::float2 yas::to_float2(CGPoint const &point) {
    return simd::float2{static_cast<float>(point.x), static_cast<float>(point.y)};
}

simd::float2 yas::to_float2(simd::float4 const &vec) {
    return simd::float2{vec.x, vec.y};
}

simd::float4 yas::to_float4(simd::float2 const &vec) {
    return simd::float4{vec.x, vec.y, 0.0f, 1.0f};
}

bool yas::contains(ui::region const &region, ui::point const &pos) {
    float const sum_x = region.origin.x + region.size.width;
    float const min_x = std::min(region.origin.x, sum_x);
    float const max_x = std::max(region.origin.x, sum_x);
    float const sum_y = region.origin.y + region.size.height;
    float const min_y = std::min(region.origin.y, sum_y);
    float const max_y = std::max(region.origin.y, sum_y);

    return min_x <= pos.x && pos.x < max_x && min_y <= pos.y && pos.y < max_y;
}

std::string yas::to_string(ui::pivot const &pivot) {
    switch (pivot) {
        case ui::pivot::left:
            return "left";
        case ui::pivot::center:
            return "center";
        case ui::pivot::right:
            return "right";
    }
}

std::string yas::to_string(ui::uint_origin const &origin) {
    return "{" + std::to_string(origin.x) + ", " + std::to_string(origin.y) + "}";
}

std::string yas::to_string(ui::uint_size const &size) {
    return "{" + std::to_string(size.width) + ", " + std::to_string(size.height) + "}";
}

std::string yas::to_string(ui::uint_region const &region) {
    return "{" + to_string(region.origin) + ", " + to_string(region.size) + "}";
}

std::string yas::to_string(ui::float_origin const &origin) {
    return "{" + std::to_string(origin.x) + ", " + std::to_string(origin.y) + "}";
}

std::string yas::to_string(ui::float_size const &size) {
    return "{" + std::to_string(size.width) + ", " + std::to_string(size.height) + "}";
}

std::string yas::to_string(ui::region const &region) {
    return "{" + to_string(region.origin) + ", " + to_string(region.size) + "}";
}

std::string yas::to_string(ui::point const &point) {
    return "{" + std::to_string(point.x) + ", " + std::to_string(point.y) + "}";
}

std::string yas::to_string(ui::size const &size) {
    return "{" + std::to_string(size.width) + ", " + std::to_string(size.height) + "}";
}

std::string yas::to_string(ui::color const &color) {
    return "{" + std::to_string(color.red) + ", " + std::to_string(color.green) + ", " + std::to_string(color.blue) +
           "}";
}

std::string yas::to_string(simd::float2 const &value) {
    return "{" + std::to_string(value.x) + ", " + std::to_string(value.y) + "}";
}

std::string yas::to_string(simd::float3 const &value) {
    return "{" + std::to_string(value.x) + ", " + std::to_string(value.y) + ", " + std::to_string(value.z) + "}";
}

std::string yas::to_string(simd::float4 const &value) {
    return "{" + std::to_string(value.x) + ", " + std::to_string(value.y) + ", " + std::to_string(value.z) + ", " +
           std::to_string(value.w) + "}";
}

std::string yas::to_string(simd::float4x4 const &matrix) {
    return "{" + to_string(matrix.columns[0]) + ", " + to_string(matrix.columns[1]) + ", " +
           to_string(matrix.columns[2]) + ", " + to_string(matrix.columns[3]) + "}";
}

#pragma mark -

bool yas::is_equal(simd::float2 const &lhs, simd::float2 const &rhs) {
    return lhs.x == rhs.x && lhs.y == rhs.y;
}

bool yas::is_equal(simd::float3 const &lhs, simd::float3 const &rhs) {
    return lhs.x == rhs.x && lhs.y == rhs.y && lhs.z == rhs.z;
}

bool yas::is_equal(simd::float4 const &lhs, simd::float4 const &rhs) {
    return lhs.x == rhs.x && lhs.y == rhs.y && lhs.z == rhs.z && lhs.w == rhs.w;
}

bool yas::is_equal(simd::float4x4 const &lhs, simd::float4x4 const &rhs) {
    return (&lhs == &rhs) || memcmp(&lhs, &rhs, sizeof(simd::float4x4)) == 0;
}

bool operator==(yas::ui::uint_origin const &lhs, yas::ui::uint_origin const &rhs) {
    return lhs.x == rhs.x && lhs.y == rhs.y;
}

bool operator!=(yas::ui::uint_origin const &lhs, yas::ui::uint_origin const &rhs) {
    return lhs.x != rhs.x || lhs.y != rhs.y;
}

bool operator==(yas::ui::uint_size const &lhs, yas::ui::uint_size const &rhs) {
    return lhs.width == rhs.width && lhs.height == rhs.height;
}

bool operator!=(yas::ui::uint_size const &lhs, yas::ui::uint_size const &rhs) {
    return lhs.width != rhs.width || lhs.height != rhs.height;
}

bool operator==(yas::ui::uint_region const &lhs, yas::ui::uint_region const &rhs) {
    return lhs.origin == rhs.origin && lhs.size == rhs.size;
}

bool operator!=(yas::ui::uint_region const &lhs, yas::ui::uint_region const &rhs) {
    return lhs.origin != rhs.origin || lhs.size != rhs.size;
}

bool operator==(yas::ui::float_origin const &lhs, yas::ui::float_origin const &rhs) {
    return lhs.x == rhs.x && lhs.y == rhs.y;
}

bool operator!=(yas::ui::float_origin const &lhs, yas::ui::float_origin const &rhs) {
    return lhs.x != rhs.x || lhs.y != rhs.y;
}

bool operator==(yas::ui::float_size const &lhs, yas::ui::float_size const &rhs) {
    return lhs.width == rhs.width && lhs.height == rhs.height;
}

bool operator!=(yas::ui::float_size const &lhs, yas::ui::float_size const &rhs) {
    return lhs.width != rhs.width || lhs.height != rhs.height;
}

bool operator==(yas::ui::float_range const &lhs, yas::ui::float_range const &rhs) {
    return lhs.location == rhs.location && lhs.length == rhs.length;
}

bool operator!=(yas::ui::float_range const &lhs, yas::ui::float_range const &rhs) {
    return lhs.location != rhs.location || lhs.length != rhs.length;
}

bool operator==(yas::ui::region const &lhs, yas::ui::region const &rhs) {
    return lhs.origin == rhs.origin && lhs.size == rhs.size;
}

bool operator!=(yas::ui::region const &lhs, yas::ui::region const &rhs) {
    return lhs.origin != rhs.origin || lhs.size != rhs.size;
}

std::ostream &operator<<(std::ostream &os, yas::ui::uint_origin const &origin) {
    os << to_string(origin);
    return os;
}

std::ostream &operator<<(std::ostream &os, yas::ui::uint_size const &size) {
    os << to_string(size);
    return os;
}

std::ostream &operator<<(std::ostream &os, yas::ui::uint_region const &region) {
    os << to_string(region);
    return os;
}

std::ostream &operator<<(std::ostream &os, yas::ui::float_origin const &origin) {
    os << to_string(origin);
    return os;
}

std::ostream &operator<<(std::ostream &os, yas::ui::float_size const &size) {
    os << to_string(size);
    return os;
}

std::ostream &operator<<(std::ostream &os, yas::ui::region const &region) {
    os << to_string(region);
    return os;
}

std::ostream &operator<<(std::ostream &os, yas::ui::point const &point) {
    os << to_string(point);
    return os;
}

std::ostream &operator<<(std::ostream &os, yas::ui::size const &size) {
    os << to_string(size);
    return os;
}

std::ostream &operator<<(std::ostream &os, yas::ui::color const &color) {
    os << to_string(color);
    return os;
}

std::ostream &operator<<(std::ostream &os, simd::float2 const &vec) {
    os << to_string(vec);
    return os;
}

std::ostream &operator<<(std::ostream &os, simd::float3 const &vec) {
    os << to_string(vec);
    return os;
}

std::ostream &operator<<(std::ostream &os, simd::float4 const &vec) {
    os << to_string(vec);
    return os;
}

std::ostream &operator<<(std::ostream &os, simd::float4x4 const &mat) {
    os << to_string(mat);
    return os;
}
