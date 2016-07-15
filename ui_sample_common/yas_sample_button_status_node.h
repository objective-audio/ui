//
//  yas_button_status_node.h
//

#pragma once

#include "yas_ui.h"

namespace yas {
namespace sample {
    struct button_status_node : base {
        class impl;

        explicit button_status_node(ui::font_atlas atlas = nullptr);
        button_status_node(std::nullptr_t);

        void set_status(sample::button_node::method const);

        ui::strings_node &strings_node();
    };
}
}
