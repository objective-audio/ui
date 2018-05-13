//
//  yas_ui_blur.h
//

#pragma once

#include "yas_base.h"

namespace yas::ui {
class effect;

class blur : public base {
    class impl;

   public:
    blur();
    blur(std::nullptr_t);

    void set_sigma(double const);
    double sigma() const;

    ui::effect &effect();
};
}  // namespace yas::ui
