//
//  yas_ui_big_button.h
//

#pragma once

#include <ui/yas_ui_umbrella.h>

#include "yas_sample_ptr.h"

namespace yas::sample {
struct big_button {
    void set_texture(std::shared_ptr<ui::texture> const &);

    std::shared_ptr<ui::button> &button();

    static big_button_ptr make_shared();

   private:
    float const _radius = 60;
    std::shared_ptr<ui::button> _button = ui::button::make_shared(
        {.origin = {-this->_radius, -this->_radius}, .size = {this->_radius * 2.0f, this->_radius * 2.0f}});

    big_button();
};
}  // namespace yas::sample
