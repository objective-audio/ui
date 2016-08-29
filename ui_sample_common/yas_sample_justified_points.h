//
//  yas_sample_justified_points.h
//

#pragma once

#include "yas_ui.h"

namespace yas {
namespace sample {
    struct justified_points : base {
        class impl;

        justified_points();
        justified_points(std::nullptr_t);

        virtual ~justified_points() final;

        ui::rect_plane_extension &rect_plane_ext();
    };
}
}
