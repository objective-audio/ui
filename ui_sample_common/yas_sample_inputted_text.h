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

    static inputted_text_ptr make_shared(std::shared_ptr<ui::font_atlas> const &,
                                         std::shared_ptr<ui::event_manager> const &,
                                         std::shared_ptr<ui::layout_region_source> const &safe_area_guide);

   private:
    std::shared_ptr<ui::strings> const _strings;
    observing::canceller_pool _pool;
    std::shared_ptr<ui::layout_point_guide> const _layout_guide_point = ui::layout_point_guide::make_shared();

    explicit inputted_text(std::shared_ptr<ui::font_atlas> const &atlas, std::shared_ptr<ui::event_manager> const &,
                           std::shared_ptr<ui::layout_region_source> const &safe_area_guide);

    void _update_text(std::shared_ptr<ui::event> const &event);
};
}  // namespace yas::sample
