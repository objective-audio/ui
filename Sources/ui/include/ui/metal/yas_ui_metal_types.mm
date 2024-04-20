//
//  yas_ui_metal_types.mm
//

#include "yas_ui_metal_types.h"

using namespace yas;
using namespace yas::ui;

uint_point yas::to_uint_point(MTLOrigin const origin) {
    return uint_point{static_cast<uint32_t>(origin.x), static_cast<uint32_t>(origin.y)};
}

uint_size yas::to_uint_size(MTLSize const size) {
    return uint_size{static_cast<uint32_t>(size.width), static_cast<uint32_t>(size.height)};
}

uint_region yas::to_uint_region(MTLRegion const region) {
    return uint_region{static_cast<uint32_t>(region.origin.x), static_cast<uint32_t>(region.origin.y),
                       static_cast<uint32_t>(region.size.width), static_cast<uint32_t>(region.size.height)};
}

MTLOrigin yas::to_mtl_origin(uint_point const origin) {
    return MTLOrigin{origin.x, origin.y, 0};
}

MTLSize yas::to_mtl_size(uint_size const size) {
    return MTLSize{size.width, size.height, 1};
}

MTLRegion yas::to_mtl_region(uint_region const region) {
    return MTLRegionMake2D(region.origin.x, region.origin.y, region.size.width, region.size.height);
}

MTLPrimitiveType yas::to_mtl_primitive_type(primitive_type const type) {
    switch (type) {
        case primitive_type::point:
            return MTLPrimitiveTypePoint;
        case primitive_type::line:
            return MTLPrimitiveTypeLine;
        case primitive_type::line_strip:
            return MTLPrimitiveTypeLineStrip;
        case primitive_type::triangle:
            return MTLPrimitiveTypeTriangle;
        case primitive_type::triangle_strip:
            return MTLPrimitiveTypeTriangleStrip;
    }
}

MTLTextureUsage yas::to_mtl_texture_usage(texture_usages_t const usages) {
    MTLTextureUsage result = MTLTextureUsageUnknown;

    if (usages.test(texture_usage::shader_read)) {
        result |= MTLTextureUsageShaderRead;
    }

    if (usages.test(texture_usage::shader_write)) {
        result |= MTLTextureUsageShaderWrite;
    }

    if (usages.test(texture_usage::render_target)) {
        result |= MTLTextureUsageRenderTarget;
    }

    return result;
}

MTLPixelFormat yas::to_mtl_pixel_format(pixel_format const format) {
    switch (format) {
        case pixel_format::rgba8_unorm:
            return MTLPixelFormatRGBA8Unorm;
        case pixel_format::bgra8_unorm:
            return MTLPixelFormatBGRA8Unorm;
    }
}
