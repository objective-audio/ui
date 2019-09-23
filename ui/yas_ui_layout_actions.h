//
//  yas_ui_layout_actions.h
//

#pragma once

#include "yas_ui_action.h"
#include "yas_ui_layout_guide.h"
#include "yas_ui_ptr.h"

namespace yas::ui {
class renderer;

namespace layout_action {
    struct args {
        ui::layout_guide_wptr target;
        float begin_value;
        float end_value;

        continuous_action::args continuous_action;
    };
}  // namespace layout_action

[[nodiscard]] std::shared_ptr<ui::continuous_action> make_action(layout_action::args);

struct layout_animator {
    struct args {
        ui::renderer_wptr renderer;
        std::vector<ui::layout_guide_pair> layout_guide_pairs;
        double duration = 0.3;
    };

    ~layout_animator();

    void set_value_transformer(ui::transform_f);
    ui::transform_f const &value_transformer() const;

    [[nodiscard]] static layout_animator_ptr make_shared(args);

   private:
    args _args;
    ui::transform_f _value_transformer;
    std::vector<chaining::any_observer_ptr> _observers;

    explicit layout_animator(args);

    void _prepare(ui::layout_animator_ptr const &);
};
}  // namespace yas::ui
