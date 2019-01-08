//
//  yas_ui_metal_render_encoder.h
//

#pragma once

#include <Metal/Metal.h>
#include <deque>
#include <cpp_utils/yas_base.h>
#include "yas_ui_render_encoder_protocol.h"

namespace yas::ui {
class metal_encode_info;
class metal_system;

class metal_render_encoder : public base {
    class impl;

   public:
    struct encode_result_t {
        std::size_t const encoded_mesh_count;
    };

    metal_render_encoder();
    metal_render_encoder(std::nullptr_t);

    virtual ~metal_render_encoder() final;

    std::deque<ui::metal_encode_info> const &all_encode_infos();

    encode_result_t encode(ui::metal_system &metal_system, id<MTLCommandBuffer> const commandBuffer);

    ui::render_encodable &encodable();
    ui::render_effectable &effectable();
    ui::render_stackable &stackable();

   private:
    ui::render_encodable _encodable = nullptr;
    ui::render_effectable _effectable = nullptr;
    ui::render_stackable _stackable = nullptr;
};
}  // namespace yas::ui
