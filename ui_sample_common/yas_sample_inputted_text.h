//
//  yas_sample_inputted_text.h
//

#pragma once

#include <ui/yas_ui_umbrella.h>
#include "yas_sample_ptr.h"

namespace yas::sample {
struct inputted_text {
    class impl;

    void append_text(std::string text);

    ui::strings_ptr const &strings();

    static inputted_text_ptr make_shared(ui::font_atlas_ptr const &);

   private:
    std::unique_ptr<impl> _impl;

    explicit inputted_text(ui::font_atlas_ptr const &atlas);

    void _prepare(inputted_text_ptr const &);
};
}  // namespace yas::sample
