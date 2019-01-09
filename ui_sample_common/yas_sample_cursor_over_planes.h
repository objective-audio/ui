//
//  yas_sample_cursor_over_planes.h
//

#pragma once

#include <ui/yas_ui_umbrella.h>

namespace yas::sample {
struct cursor_over_planes : base {
    class impl;

    cursor_over_planes();
    cursor_over_planes(std::nullptr_t);

    ui::node &node();
};
}  // namespace yas::sample
