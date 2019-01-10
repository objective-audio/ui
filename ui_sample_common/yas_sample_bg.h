//
//  yas_sample_bg.h
//

#pragma once

#include <ui/yas_ui_umbrella.h>

namespace yas::sample {
struct bg : base {
    class impl;

    bg();
    bg(std::nullptr_t);

    ui::rect_plane &rect_plane();
};
}  // namespace yas::sample
