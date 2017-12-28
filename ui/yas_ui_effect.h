//
//  yas_ui_effect.h
//

#pragma once

#include "yas_base.h"
#include "yas_ui_metal_effect.h"
#include <functional>
#include <Metal/Metal.h>

namespace yas {
namespace ui {
    class texture;

    class effect : public base {
        class impl;

       public:
        using metal_handler_f = std::function<void(id<MTLTexture>, id<MTLCommandBuffer> const)>;

        effect();
        effect(std::nullptr_t);

        void set_texture(ui::texture);
        void set_metal_handler(metal_handler_f);
        metal_handler_f const &metal_handler() const;

        metal_effect &metal_effect();

       private:
        ui::metal_effect _metal_effect = nullptr;
    };
}
}
