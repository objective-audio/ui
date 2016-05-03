//
//  yas_ui_metal_types.mm
//

#include "yas_ui_metal_types.h"

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
