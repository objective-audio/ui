//
//  yas_ui_button_node.h
//

#pragma once

#include "yas_ui.h"

namespace yas {
namespace ui {
    class texture;
}

namespace sample {
    struct button_node : public base {
        class impl;

        button_node();
        button_node(std::nullptr_t);

        void set_texture(ui::texture);

        ui::button &button();
    };
}
}
