//
//  yas_sample_bg_node.h
//

#pragma once

#include "yas_ui.h"

namespace yas {
namespace sample {
    struct bg_node : base {
        class impl;

        bg_node();
        bg_node(std::nullptr_t);

        ui::square &square();
    };
}
}
