//
//  yas_big_button_text.h
//

#pragma once

#include <ui/yas_ui_umbrella.h>

#include "yas_sample_ptr.h"

namespace yas::sample {
struct big_button_text {
    void set_status(ui::button::method const);

    ui::strings_ptr const &strings();

    static big_button_text_ptr make_shared(ui::font_atlas_ptr const &atlas);

   private:
    ui::strings_ptr _strings;
    ui::button::method _status;
    observing::canceller_ptr _strings_observer = nullptr;

    explicit big_button_text(ui::font_atlas_ptr const &atlas);

    void _prepare(big_button_text_ptr const &);
    void _update_strings_position();
};
}  // namespace yas::sample
