//
//  yas_big_button_text.h
//

#pragma once

#include <ui/yas_ui_umbrella.h>

#include "yas_sample_ptr.h"

namespace yas::sample {
struct big_button_text {
    void set_status(ui::button::method const);

    std::shared_ptr<ui::strings> const &strings();

    static big_button_text_ptr make_shared(std::shared_ptr<ui::font_atlas> const &atlas);

   private:
    std::shared_ptr<ui::strings> _strings;
    ui::button::method _status;
    observing::cancellable_ptr _strings_canceller = nullptr;

    explicit big_button_text(std::shared_ptr<ui::font_atlas> const &atlas);
};
}  // namespace yas::sample
