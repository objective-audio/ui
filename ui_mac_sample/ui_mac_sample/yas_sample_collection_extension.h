//
//  yas_sample_collection_extension.h
//

#pragma once

#include "yas_ui.h"

namespace yas {
namespace sample {
    struct collection_extension : public base {
        class impl;

        collection_extension();
        collection_extension(std::nullptr_t);

        ui::rect_plane_extension &rect_plane_ext();
        ui::layout_guide_rect &frame_layout_guide_rect();
    };
}
}