//
//  yas_ui_blur.h
//

#pragma once

#include <cpp_utils/yas_base.h>

namespace yas::ui {
class effect;

struct blur : base {
    class impl;

    blur();
    blur(std::nullptr_t);

    void set_sigma(double const);
    double sigma() const;

    ui::effect &effect();
};
}  // namespace yas::ui
