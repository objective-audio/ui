//
//  yas_ui_layout_actions.h
//

#pragma once

#include <ui/action/yas_ui_action.h>
#include <ui/layout/yas_ui_layout_guide.h>

namespace yas::ui {
class action_manager;

struct layout_action_args final {
    std::shared_ptr<action_group> group = nullptr;
    std::weak_ptr<layout_value_target> target;
    float begin_value;
    float end_value;

    double duration = 0.3;
    std::size_t loop_count = 1;
    transform_f value_transformer;

    time_point_t begin_time = std::chrono::system_clock::now();
    double delay = 0.0;
    action_completion_f completion;
};

[[nodiscard]] std::shared_ptr<ui::action> make_action(layout_action_args &&);

struct layout_animator_args final {
    std::weak_ptr<action_manager> action_manager;
    std::vector<ui::layout_value_guide_pair> layout_guide_pairs;
    double duration = 0.3;
    std::shared_ptr<action_group> group = nullptr;
};

struct layout_animator final {
    ~layout_animator();

    void set_value_transformer(ui::transform_f);
    [[nodiscard]] ui::transform_f const &value_transformer() const;

    [[nodiscard]] static std::shared_ptr<layout_animator> make_shared(layout_animator_args &&);

   private:
    layout_animator_args _args;
    std::vector<std::shared_ptr<action_group>> _groups;
    ui::transform_f _value_transformer;
    observing::canceller_pool _pool;

    explicit layout_animator(layout_animator_args &&);

    layout_animator(layout_animator const &) = delete;
    layout_animator(layout_animator &&) = delete;
    layout_animator &operator=(layout_animator const &) = delete;
    layout_animator &operator=(layout_animator &&) = delete;
};
}  // namespace yas::ui
