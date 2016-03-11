//
//  yas_ui_types.h
//

#pragma once

#include <Metal/Metal.h>

namespace yas {
namespace ui {
    struct uint_size {
        NSUInteger width = 0;
        NSUInteger height = 0;
    };
}

MTLSize to_mtl_size(ui::uint_size const);
}
