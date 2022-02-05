//
//  yas_ui_background.h
//

#pragma once

#include <observing/yas_observing_umbrella.h>
#include <ui/yas_ui_rgb_color.h>

namespace yas::ui {
struct background final {
    void set_rgb_color(ui::rgb_color const &);
    void set_rgb_color(ui::rgb_color &&);
    [[nodiscard]] ui::rgb_color const &rgb_color() const;
    [[nodiscard]] observing::syncable observe_rgb_color(observing::caller<ui::rgb_color>::handler_f &&);

    void set_alpha(float const &);
    [[nodiscard]] float const &alpha() const;
    [[nodiscard]] observing::syncable observe_alpha(observing::caller<float>::handler_f &&);

    [[nodiscard]] static std::shared_ptr<background> make_shared();

   private:
    observing::value::holder_ptr<ui::rgb_color> _rgb_color;
    observing::value::holder_ptr<float> _alpha;

    background();

    background(background const &) = delete;
    background(background &&) = delete;
    background &operator=(background const &) = delete;
    background &operator=(background &&) = delete;
};
}  // namespace yas::ui
