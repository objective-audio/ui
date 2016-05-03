//
//  yas_ui_types.mm
//

#include "yas_ui_types.h"

using namespace yas;

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

ui::size::size(float const w, float const h) : w(w), h(h) {
}

ui::size::size(simd::float2 v) : v(std::move(v)) {
}

bool ui::size::operator==(size const &rhs) const {
    return w == rhs.w && h == rhs.h;
}

bool ui::size::operator!=(size const &rhs) const {
    return w != rhs.w || h != rhs.h;
}

ui::size::operator bool() const {
    return w != 0 || h != 0;
}

#pragma mark -

ui::color::color() : v(0.0f) {
}

ui::color::color(float const r, float const g, float const b) : r(r), g(g), b(b) {
}

ui::color::color(simd::float3 v) : v(std::move(v)) {
}

bool ui::color::operator==(color const &rhs) const {
    return v.x == rhs.v.x && v.y == rhs.v.y && v.z == rhs.v.z;
}

bool ui::color::operator!=(color const &rhs) const {
    return v.x != rhs.v.x || v.y != rhs.v.y || v.z != rhs.v.z;
}

ui::color::operator bool() const {
    return v.x != 0 || v.y != 0 || v.z != 0;
}

#pragma mark -

ui::uint_origin yas::to_uint_origin(MTLOrigin const origin) {
    return ui::uint_origin{static_cast<uint32_t>(origin.x), static_cast<uint32_t>(origin.y)};
}

ui::uint_size yas::to_uint_size(MTLSize const size) {
    return ui::uint_size{static_cast<uint32_t>(size.width), static_cast<uint32_t>(size.height)};
}

ui::uint_region yas::to_uint_region(MTLRegion const region) {
    return ui::uint_region{static_cast<uint32_t>(region.origin.x), static_cast<uint32_t>(region.origin.y),
                           static_cast<uint32_t>(region.size.width), static_cast<uint32_t>(region.size.height)};
}

MTLOrigin yas::to_mtl_origin(ui::uint_origin const origin) {
    return MTLOrigin{origin.x, origin.y, 0};
}

MTLSize yas::to_mtl_size(ui::uint_size const size) {
    return MTLSize{size.width, size.height, 1};
}

MTLRegion yas::to_mtl_region(ui::uint_region const region) {
    return MTLRegionMake2D(region.origin.x, region.origin.y, region.size.width, region.size.height);
}

MTLPrimitiveType yas::to_mtl_primitive_type(ui::primitive_type const type) {
    switch (type) {
        case ui::primitive_type::point:
            return MTLPrimitiveTypePoint;
        case ui::primitive_type::line:
            return MTLPrimitiveTypeLine;
        case ui::primitive_type::line_strip:
            return MTLPrimitiveTypeLineStrip;
        case ui::primitive_type::triangle:
            return MTLPrimitiveTypeTriangle;
        case ui::primitive_type::triangle_strip:
            return MTLPrimitiveTypeTriangleStrip;
    }
}

simd::float2 yas::to_float2(CGPoint const &point) {
    return simd::float2{static_cast<float>(point.x), static_cast<float>(point.y)};
}

bool yas::contains(ui::float_region const &region, ui::float_origin const &origin) {
    float const sum_x = region.origin.x + region.size.width;
    float const min_x = std::min(region.origin.x, sum_x);
    float const max_x = std::max(region.origin.x, sum_x);
    float const sum_y = region.origin.y + region.size.height;
    float const min_y = std::min(region.origin.y, sum_y);
    float const max_y = std::max(region.origin.y, sum_y);

    return min_x <= origin.x && origin.x < max_x && min_y <= origin.y && origin.y < max_y;
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

std::string yas::to_string(ui::float_region const &region) {
    return "{" + to_string(region.origin) + ", " + to_string(region.size) + "}";
}

std::string yas::to_string(simd::float2 const &value) {
    return "{" + std::to_string(value.x) + ", " + std::to_string(value.y) + "}";
}

#pragma mark -

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

bool operator==(yas::ui::float_region const &lhs, yas::ui::float_region const &rhs) {
    return lhs.origin == rhs.origin && lhs.size == rhs.size;
}

bool operator!=(yas::ui::float_region const &lhs, yas::ui::float_region const &rhs) {
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

std::ostream &operator<<(std::ostream &os, yas::ui::float_region const &region) {
    os << to_string(region);
    return os;
}
