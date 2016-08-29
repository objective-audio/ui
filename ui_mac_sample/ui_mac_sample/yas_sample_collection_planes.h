//
//  yas_sample_collection_planes.h
//

#pragma once

#include "yas_ui.h"

namespace yas {
namespace sample {
    struct collection_planes : public base {
        class impl;

        collection_planes();
        collection_planes(std::nullptr_t);

        ui::rect_plane &rect_plane();
        ui::layout_guide_rect &frame_layout_guide_rect();
    };
}
}