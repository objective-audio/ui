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
    chaining::any_observer_ptr _renderer_observer = nullptr;
    chaining::any_observer_ptr _rect_observer = nullptr;

    bg();

    void _prepare(bg_ptr const &);
};
}  // namespace yas::sample
