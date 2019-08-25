//
//  yas_ui_effect.h
//

#pragma once

#include <Metal/Metal.h>
#include <functional>
#include "yas_ui_effect_protocol.h"
#include "yas_ui_metal_protocol.h"
#include "yas_ui_ptr.h"

namespace yas::ui {
class texture;

struct effect final : renderable_effect, std::enable_shared_from_this<effect> {
    class impl;

    using metal_handler_f = std::function<void(ui::texture_ptr const &src, ui::texture_ptr const &dst,
                                               std::shared_ptr<ui::metal_system> const &, id<MTLCommandBuffer> const)>;

    void set_metal_handler(metal_handler_f);
    metal_handler_f const &metal_handler() const;

    ui::renderable_effect_ptr renderable();
    ui::encodable_effect &encodable();
    ui::metal_object &metal();

    static effect::metal_handler_f const &through_metal_handler();
    [[nodiscard]] static ui::effect_ptr make_through_effect();

    [[nodiscard]] static effect_ptr make_shared();

   private:
    std::shared_ptr<impl> _impl;

    ui::encodable_effect _encodable = nullptr;
    ui::metal_object _metal = nullptr;

    effect();

    effect(effect const &) = delete;
    effect(effect &&) = delete;
    effect &operator=(effect const &) = delete;
    effect &operator=(effect &&) = delete;

    void set_textures(ui::texture_ptr const &src, ui::texture_ptr const &dst) override;
    ui::effect_updates_t &updates() override;
    void clear_updates() override;
};
}  // namespace yas::ui
