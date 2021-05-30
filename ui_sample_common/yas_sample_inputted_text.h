//
//  yas_sample_inputted_text.h
//

#pragma once

#include <ui/yas_ui_umbrella.h>

#include "yas_sample_ptr.h"

namespace yas::sample {
struct inputted_text {
    void append_text(std::string text);

    std::shared_ptr<ui::strings> const &strings();

    static inputted_text_ptr make_shared(std::shared_ptr<ui::font_atlas> const &);

   private:
    std::shared_ptr<ui::strings> _strings;
    observing::cancellable_ptr _renderer_canceller = nullptr;
    std::shared_ptr<ui::layout_guide_point> _layout_guide_point = ui::layout_guide_point::make_shared();

    explicit inputted_text(std::shared_ptr<ui::font_atlas> const &atlas);

    void _update_text(std::shared_ptr<ui::event> const &event);
};
}  // namespace yas::sample
