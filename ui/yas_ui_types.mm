//
//  yas_ui_types.mm
//

#include "yas_ui_types.h"

using namespace yas;

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
