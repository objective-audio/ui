//
//  yas_sample_touch_holder.h
//

#pragma once

#include "yas_ui.h"

namespace yas {
namespace sample {
    struct touch_holder : base {
        class impl;

        touch_holder(id<MTLDevice> const device, double const scale_factor);
        touch_holder(std::nullptr_t);

        ui::node &node();
    };
}
}
