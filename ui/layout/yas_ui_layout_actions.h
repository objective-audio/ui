//
//  yas_ui_layout_actions.h
//

#pragma once

#include <ui/yas_ui_action.h>
#include <ui/yas_ui_layout_guide.h>
#include <ui/yas_ui_ptr.h>

namespace yas::ui {
class renderer;

namespace layout_action {
    struct args {
        ui::layout_guide_wptr target;
        float begin_value;
        float end_value;

        action_args action;
        continuous_action_args continuous_action;
    };
}  // namespace layout_action

[[nodiscard]] std::shared_ptr<ui::action> make_action(layout_action::args);

struct layout_animator {
    struct args {
        ui::renderer_wptr renderer;
        std::vector<ui::layout_guide_pair> layout_guide_pairs;
        double duration = 0.3;
    };

    ~layout_animator();

    void set_value_transformer(ui::transform_f);
    [[nodiscard]] ui::transform_f const &value_transformer() const;

    [[nodiscard]] static layout_animator_ptr make_shared(args);

   private:
    args _args;
    ui::transform_f _value_transformer;
    observing::canceller_pool _pool;

    explicit layout_animator(args);

    layout_animator(layout_animator const &) = delete;
    layout_animator(layout_animator &&) = delete;
    layout_animator &operator=(layout_animator const &) = delete;
    layout_animator &operator=(layout_animator &&) = delete;
};
}  // namespace yas::ui
