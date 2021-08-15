//
//  yas_ui_metal_view_controller_dependency_objc.h
//

#pragma once

#include <cstdint>

@protocol MTLDevice;

namespace yas::ui {
struct metal_system_for_view {
    virtual ~metal_system_for_view() = default;

    [[nodiscard]] virtual id<MTLDevice> mtlDevice() = 0;
    [[nodiscard]] virtual uint32_t sample_count() = 0;
};
}  // namespace yas::ui
