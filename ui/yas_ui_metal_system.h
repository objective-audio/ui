//
//  yas_ui_metal_system.h
//

#pragma once

#include <CoreGraphics/CoreGraphics.h>
#include <cpp_utils/yas_base.h>
#include "yas_ui_metal_system_protocol.h"

namespace yas::ui {
struct metal_system : base {
    class impl;

    explicit metal_system(id<MTLDevice> const);
    metal_system(id<MTLDevice> const, uint32_t const sample_count);
    metal_system(std::nullptr_t);

    virtual ~metal_system() final;

    std::size_t last_encoded_mesh_count() const;

    ui::makable_metal_system &makable();
    ui::renderable_metal_system &renderable();

    ui::testable_metal_system testable();

   private:
    ui::makable_metal_system _makable = nullptr;
    ui::renderable_metal_system _renderable = nullptr;
};
}  // namespace yas::ui
