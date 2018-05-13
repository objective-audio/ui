//
//  yas_ui_layout_actions.h
//

#pragma once

#include "yas_ui_action.h"
#include "yas_ui_layout_guide.h"

namespace yas::ui {
class renderer;

namespace layout_action {
    struct args {
        weak<ui::layout_guide> target;
        float begin_value;
        float end_value;

        continuous_action::args continuous_action;
    };
}  // namespace layout_action

[[nodiscard]] ui::continuous_action make_action(layout_action::args);

class layout_animator : public base {
   public:
    class impl;

    struct args {
        weak<ui::renderer> renderer;
        std::vector<ui::layout_guide_pair> layout_guide_pairs;
        double duration = 0.3;
    };

    explicit layout_animator(args);
    layout_animator(std::nullptr_t);

    void set_value_transformer(ui::transform_f);
    ui::transform_f const &value_transformer() const;
};
}  // namespace yas::ui
