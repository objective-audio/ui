//
//  yas_sample_justified_points_extension.h
//

#pragma once

#include "yas_ui.h"

namespace yas {
namespace sample {
    struct justified_points_extension : base {
        class impl;

        justified_points_extension();
        justified_points_extension(std::nullptr_t);

        virtual ~justified_points_extension() final;

        ui::rect_plane_extension &rect_plane_ext();
    };
}
}
