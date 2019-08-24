//
//  yas_ui_big_button.h
//

#pragma once

#include <ui/yas_ui_umbrella.h>
#include "yas_sample_ptr.h"

namespace yas::sample {
struct big_button {
    class impl;

    void set_texture(ui::texture_ptr const &);

    std::shared_ptr<ui::button> &button();

    static big_button_ptr make_shared();

   private:
    std::unique_ptr<impl> _impl;

    big_button();
};
}  // namespace yas::sample
