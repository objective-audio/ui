//
//  yas_ui_metal_render_encoder_dependency.h
//

#pragma once

#include <Metal/Metal.h>

namespace yas::ui {
struct encodable_effect {
    virtual ~encodable_effect() = default;

    virtual void encode(id<MTLCommandBuffer> const) = 0;

    [[nodiscard]] static std::shared_ptr<encodable_effect> cast(std::shared_ptr<encodable_effect> const &encodable) {
        return encodable;
    }
};
}  // namespace yas::ui
