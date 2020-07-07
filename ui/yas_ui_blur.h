//
//  yas_ui_blur.h
//

#pragma once

#include <chaining/yas_chaining_umbrella.h>

#include "yas_ui_effect.h"
#include "yas_ui_ptr.h"

namespace yas::ui {
struct blur {
    void set_sigma(double const);
    double sigma() const;

    ui::effect_ptr const &effect() const;

    [[nodiscard]] static blur_ptr make_shared();

   private:
    chaining::value::holder_ptr<double> _sigma = chaining::value::holder<double>::make_shared(0.0);
    ui::effect_ptr _effect;
    chaining::any_observer_ptr _sigma_observer = nullptr;

    blur();

    blur(blur const &) = delete;
    blur(blur &&) = delete;
    blur &operator=(blur const &) = delete;
    blur &operator=(blur &&) = delete;

    void _prepare(std::shared_ptr<blur> &);
    void _update_effect_handler();
};
}  // namespace yas::ui
