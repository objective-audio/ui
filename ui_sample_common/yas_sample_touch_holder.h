//
//  yas_sample_touch_holder.h
//

#pragma once

#include "yas_ui.h"

namespace yas {
namespace sample {
    struct touch_holder : base {
        class impl;

        touch_holder();
        touch_holder(std::nullptr_t);

        ui::node &node();
    };
}
}
