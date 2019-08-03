//
//  yas_ui_blur.h
//

#pragma once

#include <cpp_utils/yas_base.h>

namespace yas::ui {
class effect;

struct blur : base {
    class impl;

    void set_sigma(double const);
    double sigma() const;

    ui::effect &effect();

   private:
    blur();

   public:
    static std::shared_ptr<blur> make_shared();
};
}  // namespace yas::ui
