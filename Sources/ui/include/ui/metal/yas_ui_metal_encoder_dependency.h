//
//  yas_ui_metal_encoder_dependency.h
//

#pragma once

#include <Metal/Metal.h>
#include <ui/common/yas_ui_types.h>

namespace yas::ui {
struct system_for_metal_encoder {
    virtual ~system_for_metal_encoder() = default;

    virtual void prepare_uniforms_buffer(uint32_t const uniforms_count) = 0;
    virtual void mesh_encode(std::shared_ptr<mesh> const &, id<MTLRenderCommandEncoder> const,
                             std::shared_ptr<metal_encode_info> const &) = 0;
};

struct effect_for_metal_encoder {
    virtual ~effect_for_metal_encoder() = default;

    virtual void encode(id<MTLCommandBuffer> const) = 0;
};
}  // namespace yas::ui
