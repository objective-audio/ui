//
//  yas_ui_effect.h
//

#pragma once

#include <Metal/Metal.h>
#include <ui/yas_ui_metal_dependency.h>
#include <ui/yas_ui_metal_render_encoder_dependency.h>
#include <ui/yas_ui_renderer_dependency.h>

#include <functional>

namespace yas::ui {
class texture;

struct effect final : renderable_effect, encodable_effect, metal_object {
    using metal_handler_f = std::function<void(std::shared_ptr<texture> const &src, std::shared_ptr<texture> const &dst,
                                               std::shared_ptr<ui::metal_system> const &, id<MTLCommandBuffer> const)>;

    void set_metal_handler(metal_handler_f);
    [[nodiscard]] metal_handler_f const &metal_handler() const;

    [[nodiscard]] static effect::metal_handler_f const &through_metal_handler();
    [[nodiscard]] static std::shared_ptr<effect> make_through_effect();

    [[nodiscard]] static std::shared_ptr<effect> make_shared();

   private:
    std::shared_ptr<texture> _src_texture = nullptr;
    std::shared_ptr<texture> _dst_texture = nullptr;
    std::shared_ptr<metal_system> _metal_system = nullptr;
    ui::effect_updates_t _updates;
    metal_handler_f _metal_handler = nullptr;

    effect();

    effect(effect const &) = delete;
    effect(effect &&) = delete;
    effect &operator=(effect const &) = delete;
    effect &operator=(effect &&) = delete;

    void set_textures(std::shared_ptr<texture> const &src, std::shared_ptr<texture> const &dst) override;
    ui::effect_updates_t &updates() override;
    void clear_updates() override;
    void encode(id<MTLCommandBuffer> const) override;

    ui::setup_metal_result metal_setup(std::shared_ptr<ui::metal_system> const &) override;
};
}  // namespace yas::ui
