//
//  yas_ui_types.mm
//

#include "yas_ui_types.h"

using namespace yas;

ui::uint_origin yas::to_uint_origin(MTLOrigin const origin) {
    return ui::uint_origin{static_cast<UInt32>(origin.x), static_cast<UInt32>(origin.y)};
}

ui::uint_size yas::to_uint_size(MTLSize const size) {
    return ui::uint_size{static_cast<UInt32>(size.width), static_cast<UInt32>(size.height)};
}

ui::uint_region yas::to_uint_region(MTLRegion const region) {
    return ui::uint_region{static_cast<UInt32>(region.origin.x), static_cast<UInt32>(region.origin.y),
                           static_cast<UInt32>(region.size.width), static_cast<UInt32>(region.size.height)};
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
