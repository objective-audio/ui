//
//  yas_sample_modifier_text.h
//

#pragma once

#include <ui/yas_ui_umbrella.h>

#include "yas_sample_ptr.h"

namespace yas::sample {
struct modifier_text {
    ui::strings_ptr const &strings();

    static modifier_text_ptr make_shared(ui::font_atlas_ptr const &, ui::layout_guide_ptr const &bottom_guide);

   private:
    ui::strings_ptr _strings;
    ui::layout_guide_ptr _bottom_guide;
    observing::canceller_ptr _renderer_canceller = nullptr;

    explicit modifier_text(ui::font_atlas_ptr const &, ui::layout_guide_ptr const &bottom_guide);

    void _prepare(modifier_text_ptr const &);
    void _update_text(ui::event_ptr const &event, std::unordered_set<ui::modifier_flags> &flags);
};
}  // namespace yas::sample
