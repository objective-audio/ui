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

        ui::makable_metal_system &makable();
        ui::renderable_metal_system &renderable();

#if YAS_TEST
        ui::testable_metal_system testable();
#endif

       private:
        ui::makable_metal_system _makable = nullptr;
        ui::renderable_metal_system _renderable = nullptr;
    };
}
}
