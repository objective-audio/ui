//
//  yas_ui_metal_view_controller_dependency_objc.h
//

#pragma once

#include <ui/yas_ui_objc.h>
#include <ui/yas_ui_types.h>

@class YASUIMetalView;

namespace yas::ui {
struct view_metal_system_interface {
    virtual ~view_metal_system_interface() = default;

    [[nodiscard]] virtual id<MTLDevice> mtlDevice() = 0;
    [[nodiscard]] virtual uint32_t sample_count() = 0;
};
}
