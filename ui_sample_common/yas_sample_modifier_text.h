//
//  yas_sample_modifier_text.h
//

#pragma once

#include <ui/yas_ui_umbrella.h>

#include "yas_sample_ptr.h"

namespace yas::sample {
struct modifier_text {
    std::shared_ptr<ui::strings> const &strings();

    static modifier_text_ptr make_shared(std::shared_ptr<ui::font_atlas> const &,
                                         std::shared_ptr<ui::layout_value_guide> const &bottom_guide);

   private:
    std::shared_ptr<ui::strings> const _strings;
    std::shared_ptr<ui::layout_value_guide> const _bottom_guide;
    observing::cancellable_ptr _renderer_canceller = nullptr;

    explicit modifier_text(std::shared_ptr<ui::font_atlas> const &,
                           std::shared_ptr<ui::layout_value_guide> const &bottom_guide);

    void _update_text(std::shared_ptr<ui::event> const &event, std::unordered_set<ui::modifier_flags> &flags);
};
}  // namespace yas::sample
