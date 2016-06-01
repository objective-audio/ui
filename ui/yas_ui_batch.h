//
//  yas_ui_batch.h
//

#pragma once

#include "yas_base.h"
#include "yas_ui_render_encoder_protocol.h"

namespace yas {
namespace ui {
    class node;
    class renderable_batch;
    class metal_object;

    class batch : public base {
        class impl;

       public:
        batch();
        batch(std::nullptr_t);

        ui::renderable_batch renderable();
        ui::render_encodable encodable();
        ui::metal_object metal();
    };
}
}
