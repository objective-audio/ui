#pragma once

#include <ui/common/yas_ui_common_dependency.h>
#include <ui/cursor_tracker/yas_ui_cursor_tracker_types.h>
#include <ui/node/yas_ui_node.h>
#include <ui/standard/yas_ui_standard.h>

namespace yas::ui {
struct cursor_tracker final {
    using phase = cursor_tracker_phase;
    using context = cursor_tracker_context;

    struct tracking_value {
        std::shared_ptr<ui::event> event;
        std::size_t collider_idx;
    };

    [[nodiscard]] static std::shared_ptr<cursor_tracker> make_shared(std::shared_ptr<ui::standard> const &,
                                                                     std::shared_ptr<ui::node> const &);
    [[nodiscard]] static std::shared_ptr<cursor_tracker> make_shared(std::shared_ptr<ui::collider_detectable> const &,
                                                                     std::shared_ptr<ui::event_observable> const &,
                                                                     std::shared_ptr<ui::renderer_observable> const &,
                                                                     std::shared_ptr<ui::node> const &);

    void cancel_tracking();

    std::optional<tracking_value> const &tracking() const;

    observing::endable observe(std::function<void(context const &)> &&);

   private:
    std::weak_ptr<ui::collider_detectable> const _weak_detector;
    std::weak_ptr<ui::node> const _weak_node;

    std::optional<tracking_value> _tracking = std::nullopt;

    observing::notifier_ptr<context> const _notifier;
    observing::canceller_pool _pool;

    cursor_tracker(std::shared_ptr<ui::collider_detectable> const &, std::shared_ptr<ui::event_observable> const &,
                   std::shared_ptr<ui::renderer_observable> const &, std::shared_ptr<ui::node> const &);

    std::vector<std::shared_ptr<ui::collider>> const &_colliders() const;
    void _update_tracking(std::shared_ptr<ui::event> const &);
    void _leave_or_enter_or_move_tracking(std::shared_ptr<ui::event> const &event, bool needs_move);
    void _cancel_tracking(std::shared_ptr<ui::event> const &);
    void _notify(phase const, std::shared_ptr<ui::event> const &, std::size_t const collider_idx);
    bool _is_tracking(std::shared_ptr<ui::event> const &, std::optional<std::size_t> const collider_idx) const;
    void _set_tracking(std::shared_ptr<ui::event> const &, std::size_t const collider_idx);
    void _reset_tracking();
};
}  // namespace yas::ui
