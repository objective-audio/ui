//
//  yas_sample_inputted_text.h
//

#pragma once

#include <ui/yas_ui_umbrella.h>

#include "yas_sample_ptr.h"

namespace yas::sample {
struct inputted_text {
    void append_text(std::string text);

    ui::strings_ptr const &strings();

    static inputted_text_ptr make_shared(ui::font_atlas_ptr const &);

   private:
    ui::strings_ptr _strings;
    chaining::any_observer_ptr _renderer_observer = nullptr;
    ui::layout_guide_point_ptr _layout_guide_point = ui::layout_guide_point::make_shared();

    explicit inputted_text(ui::font_atlas_ptr const &atlas);

    void _prepare(inputted_text_ptr const &);
    void _update_text(ui::event_ptr const &event);
};
}  // namespace yas::sample
