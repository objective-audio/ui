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
    class node_renderer;
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

        button_node(id<MTLDevice> const device, double const scale_factor);
        button_node(std::nullptr_t);

        subject<button_node, button_method> &subject();

        ui::square_node &square_node();
    };
}

std::string to_string(sample::button_method const &);
}
