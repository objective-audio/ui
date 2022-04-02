//
//  yas_ui_button.h
//

#pragma once

#include <cpp_utils/yas_flagset.h>
#include <observing/yas_observing_umbrella.h>
#include <ui/yas_ui_common_dependency.h>
#include <ui/yas_ui_event_types.h>
#include <ui/yas_ui_layout_guide.h>
#include <ui/yas_ui_rect_plane.h>
#include <ui/yas_ui_touch_tracker_types.h>
#include <ui/yas_ui_types.h>

namespace yas::ui {
struct button final {
    using phase = touch_tracker_phase;

    struct context {
        phase const phase;
        ui::touch_event const &touch;
    };

    void set_texture(std::shared_ptr<texture> const &);
    [[nodiscard]] std::shared_ptr<texture> const &texture() const;

    [[nodiscard]] std::size_t state_count() const;
    void set_state_index(std::size_t const);
    [[nodiscard]] std::size_t state_index() const;

    void set_can_begin_tracking(std::function<bool(std::shared_ptr<event> const &)> &&);
    void set_can_indicate_tracking(std::function<bool(std::shared_ptr<event> const &)> &&);

    void cancel_tracking();

    [[nodiscard]] observing::endable observe(std::function<void(context const &)> &&);

    [[nodiscard]] std::shared_ptr<rect_plane> const &rect_plane();

    [[nodiscard]] std::shared_ptr<layout_region_guide> const &layout_guide();

    [[nodiscard]] static std::shared_ptr<button> make_shared(ui::region const &,
                                                             std::shared_ptr<ui::event_observable> const &,
                                                             std::shared_ptr<ui::collider_detectable> const &,
                                                             std::shared_ptr<ui::renderer_observable> const &);
    [[nodiscard]] static std::shared_ptr<button> make_shared(ui::region const &, std::size_t const state_count,
                                                             std::shared_ptr<ui::event_observable> const &,
                                                             std::shared_ptr<ui::collider_detectable> const &,
                                                             std::shared_ptr<ui::renderer_observable> const &);

   private:
    std::shared_ptr<ui::rect_plane> _rect_plane;
    std::shared_ptr<ui::layout_region_guide> _layout_guide;
    observing::notifier_ptr<context> _notifier = observing::notifier<context>::make_shared();
    std::size_t _state_idx = 0;
    std::size_t _state_count;
    std::function<bool(std::shared_ptr<event> const &)> _can_begin_tracking = nullptr;
    std::function<bool(std::shared_ptr<event> const &)> _can_indicate_tracking = nullptr;
    std::weak_ptr<ui::collider_detectable> _weak_detector;
    std::shared_ptr<event> _tracking_event = nullptr;
    observing::canceller_pool _pool;

    button(ui::region const &region, std::size_t const state_count, std::shared_ptr<ui::event_observable> const &,
           std::shared_ptr<ui::collider_detectable> const &, std::shared_ptr<ui::renderer_observable> const &);

    button(button const &) = delete;
    button(button &&) = delete;
    button &operator=(button const &) = delete;
    button &operator=(button &&) = delete;

    bool _is_tracking();
    bool _is_tracking(std::shared_ptr<event> const &);
    void _set_tracking_event(std::shared_ptr<event> const &);
    void _update_rect_positions(ui::region const &region, std::size_t const state_count);
    void _update_rect_index();
    observing::cancellable_ptr _make_leave_observings();
    observing::cancellable_ptr _make_collider_observings();
    void _update_tracking(std::shared_ptr<event> const &event);
    void _leave_or_enter_or_move_tracking(std::shared_ptr<event> const &);
    void _cancel_tracking(std::shared_ptr<event> const &event);
    void _send_notify(phase const method, std::shared_ptr<event> const &);
    bool _can_begin_tracking_value(std::shared_ptr<event> const &) const;
    bool _can_indicate_tracking_value(std::shared_ptr<event> const &) const;
};
}  // namespace yas::ui

namespace yas {
std::size_t to_rect_index(std::size_t const state_idx, bool is_tracking);
std::string to_string(ui::button::phase const &);
}  // namespace yas

std::ostream &operator<<(std::ostream &, yas::ui::button::phase const &);
