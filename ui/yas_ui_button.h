//
//  yas_ui_button.h
//

#pragma once

#include <chaining/yas_chaining_umbrella.h>
#include <cpp_utils/yas_flagset.h>
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
        std::shared_ptr<ui::button> const &button;
        ui::touch_event const &touch;
    };

    virtual ~button();

    void set_texture(ui::texture_ptr const &);
    ui::texture_ptr const &texture() const;

    std::size_t state_count() const;
    void set_state_index(std::size_t const);
    std::size_t state_index() const;

    void cancel_tracking();

    using chain_pair_t = std::pair<method, context>;
    [[nodiscard]] observing::canceller_ptr observe(observing::caller<chain_pair_t>::handler_f &&);

    ui::rect_plane_ptr const &rect_plane();

    ui::layout_guide_rect_ptr const &layout_guide_rect();

    [[nodiscard]] static button_ptr make_shared(ui::region const &);
    [[nodiscard]] static button_ptr make_shared(ui::region const &, std::size_t const state_count);

   private:
    std::weak_ptr<button> _weak_button;
    ui::rect_plane_ptr _rect_plane;
    ui::layout_guide_rect_ptr _layout_guide_rect;
    observing::notifier_ptr<chain_pair_t> _notifier = observing::notifier<chain_pair_t>::make_shared();
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
