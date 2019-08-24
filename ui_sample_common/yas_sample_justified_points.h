//
//  yas_sample_justified_points.h
//

#pragma once

#include <ui/yas_ui_umbrella.h>
#include "yas_sample_ptr.h"

namespace yas::sample {
struct justified_points final {
    class impl;

    virtual ~justified_points();

    ui::rect_plane_ptr const &rect_plane();

    static justified_points_ptr make_shared();

   private:
    std::unique_ptr<impl> _impl;

    justified_points();

    void _prepare(justified_points_ptr const &);
};
}  // namespace yas::sample
