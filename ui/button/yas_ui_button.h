//
//  yas_ui_button.h
//

#pragma once

#include <cpp_utils/yas_flagset.h>
#include <observing/yas_observing_umbrella.h>
#include <ui/yas_ui_layout_guide.h>
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

    void set_texture(std::shared_ptr<texture> const &);
    [[nodiscard]] std::shared_ptr<texture> const &texture() const;

    [[nodiscard]] std::size_t state_count() const;
    void set_state_index(std::size_t const);
    [[nodiscard]] std::size_t state_index() const;

    void cancel_tracking();

    [[nodiscard]] observing::endable observe(observing::caller<context>::handler_f &&);

    [[nodiscard]] std::shared_ptr<rect_plane> const &rect_plane();

    [[nodiscard]] std::shared_ptr<layout_guide_rect> const &layout_guide_rect();

    [[nodiscard]] static std::shared_ptr<button> make_shared(ui::region const &);
    [[nodiscard]] static std::shared_ptr<button> make_shared(ui::region const &, std::size_t const state_count);

   private:
    std::shared_ptr<ui::rect_plane> _rect_plane;
    std::shared_ptr<ui::layout_guide_rect> _layout_guide_rect;
    observing::notifier_ptr<context> _notifier = observing::notifier<context>::make_shared();
    std::size_t _state_idx = 0;
    std::size_t _state_count;

    std::shared_ptr<event> _tracking_event = nullptr;
    observing::canceller_pool _pool;

    button(ui::region const &region, std::size_t const state_count);

    button(button const &) = delete;
    button(button &&) = delete;
    button &operator=(button const &) = delete;
    button &operator=(button &&) = delete;

    bool _is_tracking();
    bool _is_tracking(std::shared_ptr<event> const &);
    void _set_tracking_event(std::shared_ptr<event> const &);
    void _update_rect_positions(ui::region const &region, std::size_t const state_count);
    void _update_rect_index();
    observing::cancellable_ptr _make_leave_chains();
    observing::cancellable_ptr _make_collider_chains();
    void _update_tracking(std::shared_ptr<event> const &event);
    void _leave_or_enter_or_move_tracking(std::shared_ptr<event> const &event);
    void _cancel_tracking(std::shared_ptr<event> const &event);
    void _send_notify(method const method, std::shared_ptr<event> const &event);
};
}  // namespace yas::ui

namespace yas {
std::size_t to_rect_index(std::size_t const state_idx, bool is_tracking);
std::string to_string(ui::button::method const &);
}  // namespace yas

std::ostream &operator<<(std::ostream &, yas::ui::button::method const &);
