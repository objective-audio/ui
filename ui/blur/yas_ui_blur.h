//
//  yas_ui_blur.h
//

#pragma once

#include <ui/yas_ui_effect.h>

#include <observing/yas_observing_umbrella.hpp>

namespace yas::ui {
struct blur final {
    void set_sigma(double const);
    [[nodiscard]] double sigma() const;

    [[nodiscard]] std::shared_ptr<effect> const &effect() const;

    [[nodiscard]] static std::shared_ptr<blur> make_shared();

   private:
    double _sigma = 0.0;
    std::shared_ptr<ui::effect> _effect;

    blur();

    blur(blur const &) = delete;
    blur(blur &&) = delete;
    blur &operator=(blur const &) = delete;
    blur &operator=(blur &&) = delete;

    void _update_effect_handler();
};
}  // namespace yas::ui
