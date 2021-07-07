//
//  yas_sample_draw_call_text.h
//

#pragma once

#include <cpp_utils/yas_timer.h>
#include <ui/yas_ui_umbrella.h>

#include "yas_sample_ptr.h"

namespace yas::sample {
struct draw_call_text {
    std::shared_ptr<ui::strings> const &strings();

    static draw_call_text_ptr make_shared(std::shared_ptr<ui::font_atlas> const &,
                                          std::shared_ptr<ui::metal_system> const &,
                                          std::shared_ptr<ui::layout_region_source> const &safe_area_guide);

   private:
    std::shared_ptr<ui::strings> _strings;
    std::optional<timer> _timer = std::nullopt;
    std::weak_ptr<ui::metal_system> _weak_metal_system;
    observing::canceller_pool _pool;

    draw_call_text(std::shared_ptr<ui::font_atlas> const &, std::shared_ptr<ui::metal_system> const &,
                   std::shared_ptr<ui::layout_region_source> const &safe_area_guide);

    void _update_text();
};
}  // namespace yas::sample
