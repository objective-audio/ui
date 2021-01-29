//
//  yas_sample_justified_points.h
//

#pragma once

#include <ui/yas_ui_umbrella.h>

#include "yas_sample_ptr.h"

namespace yas::sample {
struct justified_points final {
    virtual ~justified_points();

    ui::rect_plane_ptr const &rect_plane();

    static justified_points_ptr make_shared();

   private:
    ui::rect_plane_ptr _rect_plane;
    std::vector<ui::layout_guide_ptr> _x_layout_guides;
    std::vector<ui::layout_guide_ptr> _y_layout_guides;
    observing::cancellable_ptr _renderer_canceller = nullptr;
    observing::canceller_pool _guide_pool;

    justified_points();

    void _setup_colors();
    void _setup_layout_guides();
};
}  // namespace yas::sample
