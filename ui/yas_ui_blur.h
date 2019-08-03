//
//  yas_ui_blur.h
//

#pragma once

#include <cpp_utils/yas_base.h>

namespace yas::ui {
class effect;

struct blur : base {
    class impl;

    blur(std::nullptr_t);

    void set_sigma(double const);
    double sigma() const;

    ui::effect &effect();

   private:
    blur();

   public:
    static std::shared_ptr<blur> make_shared();
};
}  // namespace yas::ui
