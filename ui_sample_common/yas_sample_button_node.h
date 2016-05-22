//
//  yas_ui_button_node.h
//

#pragma once

#include "yas_ui.h"

namespace yas {
namespace ui {
    class square_node;
    class texture;
    class uint_region;
    class renderer;
}

namespace sample {
    class button_node;

    enum class button_method {
        began,
        entered,
        leaved,
        ended,
        canceled,
    };

    struct button_node : public base {
        class impl;

        button_node();
        button_node(std::nullptr_t);

        void set_texture(ui::texture);

        subject<button_node, button_method> &subject();

        ui::square_node &square_node();
    };
}

std::string to_string(sample::button_method const &);
}
