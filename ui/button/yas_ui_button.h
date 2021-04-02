//
//  yas_ui_button.h
//

#pragma once

#include <cpp_utils/yas_flagset.h>
#include <observing/yas_observing_umbrella.h>
#include <ui/yas_ui_layout_guide.h>
#include <ui/yas_ui_ptr.h>
#include <ui/yas_ui_rect_plane.h>
#include <ui/yas_ui_types.h>

namespace yas::ui {
class touch_event;

struct button final {
    enum class method {
        began,
        entered,
        moved,
        leaved,
        ended,
        canceled,
    };

    struct context {
        method const method;
        ui::touch_event const &touch;
    };

    virtual ~button();

    void set_texture(ui::texture_ptr const &);
    [[nodiscard]] ui::texture_ptr const &texture() const;

    [[nodiscard]] std::size_t state_count() const;
    void set_state_index(std::size_t const);
    [[nodiscard]] std::size_t state_index() const;

    void cancel_tracking();

    [[nodiscard]] observing::endable observe(observing::caller<context>::handler_f &&);

    [[nodiscard]] ui::rect_plane_ptr const &rect_plane();

    [[nodiscard]] ui::layout_guide_rect_ptr const &layout_guide_rect();

    [[nodiscard]] static button_ptr make_shared(ui::region const &);
    [[nodiscard]] static button_ptr make_shared(ui::region const &, std::size_t const state_count);

   private:
    ui::rect_plane_ptr _rect_plane;
    ui::layout_guide_rect_ptr _layout_guide_rect;
    observing::notifier_ptr<context> _notifier = observing::notifier<context>::make_shared();
    std::size_t _state_idx = 0;
    std::size_t _state_count;

    ui::event_ptr _tracking_event = nullptr;
    observing::canceller_pool _pool;

    button(ui::region const &region, std::size_t const state_count);

    button(button const &) = delete;
    button(button &&) = delete;
    button &operator=(button const &) = delete;
    button &operator=(button &&) = delete;

    bool _is_tracking();
    bool _is_tracking(ui::event_ptr const &);
    void _set_tracking_event(ui::event_ptr const &);
    void _update_rect_positions(ui::region const &region, std::size_t const state_count);
    void _update_rect_index();
    observing::cancellable_ptr _make_leave_chains();
    observing::cancellable_ptr _make_collider_chains();
    void _update_tracking(ui::event_ptr const &event);
    void _leave_or_enter_or_move_tracking(ui::event_ptr const &event);
    void _cancel_tracking(ui::event_ptr const &event);
    void _send_notify(method const method, ui::event_ptr const &event);
};
}  // namespace yas::ui

namespace yas {
std::size_t to_rect_index(std::size_t const state_idx, bool is_tracking);
std::string to_string(ui::button::method const &);
}  // namespace yas

std::ostream &operator<<(std::ostream &, yas::ui::button::method const &);
