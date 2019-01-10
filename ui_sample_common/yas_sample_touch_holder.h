//
//  yas_sample_touch_holder.h
//

#pragma once

#include <ui/yas_ui_umbrella.h>

namespace yas::sample {
struct touch_holder : base {
    class impl;

    touch_holder();
    touch_holder(std::nullptr_t);

    void set_texture(ui::texture);

    ui::node &node();
};
}  // namespace yas::sample
