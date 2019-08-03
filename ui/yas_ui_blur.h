//
//  yas_ui_blur.h
//

#pragma once

#include <chaining/yas_chaining_umbrella.h>

namespace yas::ui {
class effect;

struct blur {
    void set_sigma(double const);
    double sigma() const;

    ui::effect &effect();

   private:
    chaining::value::holder<double> _sigma{0.0};
    std::unique_ptr<ui::effect> _effect;
    chaining::any_observer_ptr _sigma_observer = nullptr;

    blur();

    void _prepare(std::shared_ptr<blur> &);
    void _update_effect_handler();

   public:
    static std::shared_ptr<blur> make_shared();
};
}  // namespace yas::ui
