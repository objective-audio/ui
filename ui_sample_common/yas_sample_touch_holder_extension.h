//
//  yas_sample_touch_holder_extension.h
//

#pragma once

#include "yas_ui.h"

namespace yas {
namespace sample {
    struct touch_holder_extension : base {
        class impl;

        touch_holder_extension();
        touch_holder_extension(std::nullptr_t);

        void set_texture(ui::texture);

        ui::node &node();
    };
}
}
