//
//  yas_sample_cursor.h
//

#pragma once

#include "yas_ui.h"

namespace yas::sample {
struct cursor : base {
    class impl;

    cursor();
    cursor(std::nullptr_t);

    ui::node &node();
};
}
