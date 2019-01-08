//
//  yas_ui_effect.h
//

#pragma once

#include <Metal/Metal.h>
#include <functional>
#include <cpp_utils/yas_base.h>
#include "yas_ui_effect_protocol.h"
#include "yas_ui_metal_protocol.h"

namespace yas::ui {
class texture;

class effect : public base {
    class impl;

   public:
    using metal_handler_f =
        std::function<void(ui::texture &src, ui::texture &dst, ui::metal_system &, id<MTLCommandBuffer> const)>;

    effect();
    effect(std::nullptr_t);

    void set_metal_handler(metal_handler_f);
    metal_handler_f const &metal_handler() const;

    ui::renderable_effect &renderable();
    ui::encodable_effect &encodable();
    ui::metal_object &metal();

    static effect::metal_handler_f const &through_metal_handler();
    static ui::effect make_through_effect();

   private:
    ui::renderable_effect _renderable = nullptr;
    ui::encodable_effect _encodable = nullptr;
    ui::metal_object _metal = nullptr;
};
}  // namespace yas::ui
