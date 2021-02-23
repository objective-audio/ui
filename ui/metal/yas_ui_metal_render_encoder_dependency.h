//
//  yas_ui_metal_render_encoder_dependency.h
//

#pragma once

#include <Metal/Metal.h>
#include <ui/yas_ui_ptr.h>

namespace yas::ui {
struct encodable_effect {
    virtual ~encodable_effect() = default;

    virtual void encode(id<MTLCommandBuffer> const) = 0;

    [[nodiscard]] static encodable_effect_ptr cast(encodable_effect_ptr const &encodable) {
        return encodable;
    }
};
}  // namespace yas::ui
