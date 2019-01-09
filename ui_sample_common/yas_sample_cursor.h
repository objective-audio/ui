//
//  yas_sample_cursor.h
//

#pragma once

#include <ui/yas_ui_umbrella.h>

namespace yas::sample {
struct cursor : base {
    class impl;

    cursor();
    cursor(std::nullptr_t);

    ui::node &node();
};
}  // namespace yas::sample
