//
//  yas_ui_metal_system.h
//

#pragma once

#include <CoreGraphics/CoreGraphics.h>
#include "yas_ui_metal_system_protocol.h"
#include "yas_ui_ptr.h"

namespace yas::ui {

struct metal_system final {
    class impl;

    virtual ~metal_system();

    std::size_t last_encoded_mesh_count() const;

    ui::makable_metal_system &makable();
    ui::renderable_metal_system &renderable();

    ui::testable_metal_system testable();

    [[nodiscard]] static metal_system_ptr make_shared(id<MTLDevice> const);
    [[nodiscard]] static metal_system_ptr make_shared(id<MTLDevice> const, uint32_t const sample_count);

   private:
    std::shared_ptr<impl> _impl;

    ui::makable_metal_system _makable = nullptr;
    ui::renderable_metal_system _renderable = nullptr;

    metal_system(id<MTLDevice> const, uint32_t const sample_count);

    metal_system(metal_system const &) = delete;
    metal_system(metal_system &&) = delete;
    metal_system &operator=(metal_system const &) = delete;
    metal_system &operator=(metal_system &&) = delete;

    void _prepare(metal_system_ptr const &);
};
}  // namespace yas::ui
