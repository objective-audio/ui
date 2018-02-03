//
//  yas_sample_touch_holder.h
//

#pragma once

#include "yas_ui.h"

namespace yas::sample {
struct touch_holder : base {
    class impl;

    touch_holder();
    touch_holder(std::nullptr_t);

    void set_texture(ui::texture);

    ui::node &node();
};
}
