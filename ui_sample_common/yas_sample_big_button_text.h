//
//  yas_big_button_text.h
//

#pragma once

#include <ui/yas_ui_umbrella.h>
#include "yas_sample_ptr.h"

namespace yas::sample {
struct big_button_text {
    class impl;

    void set_status(ui::button::method const);

    ui::strings_ptr const &strings();

    static big_button_text_ptr make_shared(ui::font_atlas_ptr const &atlas);

   private:
    std::unique_ptr<impl> _impl;

    explicit big_button_text(ui::font_atlas_ptr const &atlas);

    void _prepare(big_button_text_ptr const &);
};
}  // namespace yas::sample
