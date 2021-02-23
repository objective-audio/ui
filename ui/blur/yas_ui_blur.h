//
//  yas_ui_blur.h
//

#pragma once

#include <chaining/yas_chaining_umbrella.h>
#include <ui/yas_ui_effect.h>
#include <ui/yas_ui_ptr.h>

namespace yas::ui {
struct blur {
    void set_sigma(double const);
    [[nodiscard]] double sigma() const;

    [[nodiscard]] ui::effect_ptr const &effect() const;

    [[nodiscard]] static blur_ptr make_shared();

   private:
    double _sigma = 0.0;
    ui::effect_ptr _effect;

    blur();

    blur(blur const &) = delete;
    blur(blur &&) = delete;
    blur &operator=(blur const &) = delete;
    blur &operator=(blur &&) = delete;

    void _update_effect_handler();
};
}  // namespace yas::ui
