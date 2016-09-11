//
//  yas_ui_layout_actions.h
//

#pragma once

#include "yas_ui_action.h"
#include "yas_ui_layout_guide.h"

namespace yas {
namespace ui {
    class renderer;

    namespace layout_action {
        struct args {
            weak<ui::layout_guide> target;
            float start_value;
            float end_value;

            continuous_action::args continuous_action;
        };
    }

    ui::continuous_action make_action(layout_action::args);

    class layout_interporator : public base {
       public:
        class impl;

        struct args {
            weak<ui::renderer> renderer;
            std::vector<ui::layout_guide_pair> layout_guide_pairs;
            double duration = 0.3;
        };

        explicit layout_interporator(args);
        layout_interporator(std::nullptr_t);

        void set_value_transformer(ui::transform_f);
        ui::transform_f const &value_transformer() const;
    };
}
}
