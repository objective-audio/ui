//
//  yas_ui_background.h
//

#pragma once

#include <ui/action/yas_ui_action_factory_dependency.h>
#include <ui/color/yas_ui_color.h>
#include <ui/renderer/yas_ui_renderer_dependency.h>

#include <observing/umbrella.hpp>

namespace yas::ui {
struct background final : renderable_background, color_action_target, alpha_action_target {
    [[nodiscard]] static std::shared_ptr<background> make_shared();

    void set_rgb_color(ui::rgb_color const &);
    void set_rgb_color(ui::rgb_color &&) override;
    [[nodiscard]] ui::rgb_color const &rgb_color() const;
    [[nodiscard]] observing::syncable observe_rgb_color(std::function<void(ui::rgb_color const &)> &&);

    void set_alpha(float const &);
    void set_alpha(float &&) override;
    [[nodiscard]] float const &alpha() const;
    [[nodiscard]] observing::syncable observe_alpha(std::function<void(float const &)> &&);

    void set_color(ui::color const &);
    void set_color(ui::color &&);
    [[nodiscard]] ui::color color() const override;

   private:
    observing::value::holder_ptr<ui::rgb_color> _rgb_color;
    observing::value::holder_ptr<float> _alpha;

    background_updates_t _updates;

    observing::canceller_pool _pool;

    background();

    background(background const &) = delete;
    background(background &&) = delete;
    background &operator=(background const &) = delete;
    background &operator=(background &&) = delete;

    void fetch_updates(ui::tree_updates &) override;
    void clear_updates() override;
};
}  // namespace yas::ui
