//
//  yas_ui_effect.h
//

#pragma once

#include "yas_protocol.h"
#include <Metal/Metal.h>

namespace yas {
namespace ui {
    struct metal_effect : protocol {
        struct impl : protocol::impl {
            virtual void encode(id<MTLCommandBuffer> const) = 0;
        };

        explicit metal_effect(std::shared_ptr<impl>);
        metal_effect(std::nullptr_t);

        void encode(id<MTLCommandBuffer> const);
    };
}
}
