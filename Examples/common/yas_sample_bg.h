//
//  yas_sample_bg.h
//

#pragma once

#include <ui/yas_ui_umbrella.h>

#include "yas_sample_ptr.h"

namespace yas::sample {
struct bg {
    std::shared_ptr<ui::rect_plane> const &rect_plane();

    static bg_ptr make_shared(std::shared_ptr<ui::layout_region_source> const &safe_area_guide);

   private:
    std::shared_ptr<ui::rect_plane> _rect_plane = ui::rect_plane::make_shared(1);
    std::shared_ptr<ui::layout_region_guide> _layout_guide = ui::layout_region_guide::make_shared();
    observing::canceller_pool _pool;

    explicit bg(std::shared_ptr<ui::layout_region_source> const &);
};
}  // namespace yas::sample
