//
//  yas_sample_bg.h
//

#pragma once

#include <ui/yas_ui_umbrella.h>

#include "yas_sample_ptr.h"

namespace yas::sample {
struct bg {
    ui::rect_plane_ptr const &rect_plane();

    static bg_ptr make_shared();

   private:
    ui::rect_plane_ptr _rect_plane = ui::rect_plane::make_shared(1);
    ui::layout_guide_rect_ptr _layout_guide_rect = ui::layout_guide_rect::make_shared();
    observing::cancellable_ptr _renderer_canceller = nullptr;
    observing::cancellable_ptr _rect_canceller = nullptr;

    bg();
};
}  // namespace yas::sample
