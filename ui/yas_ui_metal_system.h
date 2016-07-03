//
//  yas_ui_metal_system.h
//

#pragma once

#include <CoreGraphics/CoreGraphics.h>
#include "yas_base.h"
#include "yas_ui_metal_system_protocol.h"

namespace yas {
namespace ui {
    class metal_system : public base {
       public:
        class impl;

        explicit metal_system(id<MTLDevice> const);
        metal_system(std::nullptr_t);

        id<MTLDevice> device() const;
        uint32_t sample_count() const;

        ui::renderable_metal_system &renderable();

       private:
        ui::renderable_metal_system _renderable = nullptr;
    };
}
}
