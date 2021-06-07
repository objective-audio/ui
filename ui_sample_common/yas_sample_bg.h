//
//  yas_sample_bg.h
//

#pragma once

#include <ui/yas_ui_umbrella.h>

#include "yas_sample_ptr.h"

namespace yas::sample {
struct bg {
    std::shared_ptr<ui::rect_plane> const &rect_plane();

    static bg_ptr make_shared();

   private:
    std::shared_ptr<ui::rect_plane> _rect_plane = ui::rect_plane::make_shared(1);
    std::shared_ptr<ui::layout_region_guide> _layout_guide = ui::layout_region_guide::make_shared();
    observing::cancellable_ptr _renderer_canceller = nullptr;
    observing::cancellable_ptr _region_canceller = nullptr;

    bg();
};
}  // namespace yas::sample
