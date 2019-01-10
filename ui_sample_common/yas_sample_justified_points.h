//
//  yas_sample_justified_points.h
//

#pragma once

#include <ui/yas_ui_umbrella.h>

namespace yas::sample {
struct justified_points : base {
    class impl;

    justified_points();
    justified_points(std::nullptr_t);

    virtual ~justified_points() final;

    ui::rect_plane &rect_plane();
};
}  // namespace yas::sample
