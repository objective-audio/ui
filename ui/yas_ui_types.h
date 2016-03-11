//
//  yas_ui_types.h
//

#pragma once

#include <Metal/Metal.h>

namespace yas {
namespace ui {
    struct uint_origin {
        UInt32 x = 0;
        UInt32 y = 0;
    };

    struct uint_size {
        UInt32 width = 1;
        UInt32 height = 1;
    };

    struct uint_region {
        uint_origin origin;
        uint_size size;
    };
}

ui::uint_origin to_uint_origin(MTLOrigin const);
ui::uint_size to_uint_size(MTLSize const);
ui::uint_region to_uint_region(MTLRegion const);

MTLOrigin to_mtl_origin(ui::uint_origin const);
MTLSize to_mtl_size(ui::uint_size const);
MTLRegion to_mtl_region(ui::uint_region const);
}
