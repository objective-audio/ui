//
//  yas_sample_modifier_text.h
//

#pragma once

#include <ui/yas_ui_umbrella.h>
#include "yas_sample_ptr.h"

namespace yas::sample {
struct modifier_text {
    class impl;

    ui::strings_ptr const &strings();

    static modifier_text_ptr make_shared(ui::font_atlas_ptr const &, ui::layout_guide_ptr const &bottom_guide);

   private:
    std::unique_ptr<impl> _impl;

    explicit modifier_text(ui::font_atlas_ptr const &, ui::layout_guide_ptr const &bottom_guide);

    void _prepare(modifier_text_ptr const &);
};
}  // namespace yas::sample
