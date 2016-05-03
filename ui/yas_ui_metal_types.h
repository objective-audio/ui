//
//  yas_ui_metal_types.h
//

#pragma once

#include <Metal/Metal.h>
#include "yas_ui_types.h"

namespace yas {
ui::uint_origin to_uint_origin(MTLOrigin const);
ui::uint_size to_uint_size(MTLSize const);
ui::uint_region to_uint_region(MTLRegion const);

MTLOrigin to_mtl_origin(ui::uint_origin const);
MTLSize to_mtl_size(ui::uint_size const);
MTLRegion to_mtl_region(ui::uint_region const);

MTLPrimitiveType to_mtl_primitive_type(ui::primitive_type const type);
}
