//
//  yas_ui_metal_system.h
//

#pragma once

#include <CoreGraphics/CoreGraphics.h>
#include <Metal/Metal.h>
#include "yas_base.h"
#include "yas_objc_macros.h"

namespace yas {
namespace ui {
    class renderer;

    class metal_system : public base {
       public:
        class impl;

        explicit metal_system(id<MTLDevice> const);
        metal_system(std::nullptr_t);

        id<MTLDevice> device() const;
        id<MTLBuffer> currentConstantBuffer() const;

        uint32_t constant_buffer_offset() const;
        void set_constant_buffer_offset(uint32_t const offset);

        uint32_t sample_count() const;

        void view_render(yas_objc_view *const view, ui::renderer &);
    };
}
}
