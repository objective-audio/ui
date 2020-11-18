//
//  yas_ui_effect.h
//

#pragma once

#include <Metal/Metal.h>
#include <ui/yas_ui_effect_protocol.h>
#include <ui/yas_ui_metal_protocol.h>
#include <ui/yas_ui_ptr.h>

#include <functional>

namespace yas::ui {
class texture;

struct effect final : renderable_effect, encodable_effect, metal_object {
    using metal_handler_f = std::function<void(ui::texture_ptr const &src, ui::texture_ptr const &dst,
                                               std::shared_ptr<ui::metal_system> const &, id<MTLCommandBuffer> const)>;

    void set_metal_handler(metal_handler_f);
    metal_handler_f const &metal_handler() const;

    static effect::metal_handler_f const &through_metal_handler();
    [[nodiscard]] static ui::effect_ptr make_through_effect();

    [[nodiscard]] static effect_ptr make_shared();

   private:
    ui::texture_ptr _src_texture = nullptr;
    ui::texture_ptr _dst_texture = nullptr;
    ui::metal_system_ptr _metal_system = nullptr;
    ui::effect_updates_t _updates;
    metal_handler_f _metal_handler = nullptr;

    effect();

    effect(effect const &) = delete;
    effect(effect &&) = delete;
    effect &operator=(effect const &) = delete;
    effect &operator=(effect &&) = delete;

    void set_textures(ui::texture_ptr const &src, ui::texture_ptr const &dst) override;
    ui::effect_updates_t &updates() override;
    void clear_updates() override;
    void encode(id<MTLCommandBuffer> const) override;

    ui::setup_metal_result metal_setup(std::shared_ptr<ui::metal_system> const &) override;
};
}  // namespace yas::ui
