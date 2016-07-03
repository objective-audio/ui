//
//  yas_ui_metal_render_encoder.h
//

#pragma once

#include <Metal/Metal.h>
#include <deque>
#include "yas_base.h"
#include "yas_ui_render_encoder_protocol.h"

namespace yas {
namespace ui {
    class metal_encode_info;

    class metal_render_encoder : public base {
        class impl;

       public:
        metal_render_encoder();
        metal_render_encoder(std::nullptr_t);

        std::deque<ui::metal_encode_info> const &all_encode_infos();

        void push_encode_info(ui::metal_encode_info);
        void pop_encode_info();

        ui::metal_encode_info const &current_encode_info();

        void render(ui::renderer &renderer, id<MTLCommandBuffer> const commandBuffer);

        ui::render_encodable &encodable();

       private:
        ui::render_encodable _encodable = nullptr;
    };
}
}
