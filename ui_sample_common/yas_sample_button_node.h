//
//  yas_ui_button_node.h
//

#pragma once

#include "yas_ui.h"

namespace yas {
namespace ui {
    class square;
    class texture;
    class renderer;
}

namespace sample {
    class button_node;

    struct button_node : public base {
        class impl;

        enum class method {
            began,
            entered,
            leaved,
            ended,
            canceled,
        };

        using subject_t = subject<button_node, method>;

        button_node();
        button_node(std::nullptr_t);

        void set_texture(ui::texture);

        subject_t &subject();

        ui::square &square();
    };
}

std::string to_string(sample::button_node::method const &);
}
