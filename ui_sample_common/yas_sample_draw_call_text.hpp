//
//  yas_sample_draw_call_text.hpp
//

#pragma once

#include <ui/yas_ui_umbrella.h>
#include "yas_sample_ptr.h"

namespace yas::sample {
struct draw_call_text {
    class impl;

    ui::strings_ptr const &strings();

    static draw_call_text_ptr make_shared(ui::font_atlas_ptr const &);

   private:
    std::unique_ptr<impl> _impl;

    explicit draw_call_text(ui::font_atlas_ptr const &);

    void _prepare(draw_call_text_ptr const &);
};
}  // namespace yas::sample
