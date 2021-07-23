//
//  yas_ui_event_manager.h
//

#pragma once

#include <observing/yas_observing_umbrella.h>
#include <ui/yas_ui_common_dependency.h>
#include <ui/yas_ui_event.h>
#include <ui/yas_ui_metal_view_dependency.h>

namespace yas::ui {
struct event_manager : metal_view_event_manager_interface, event_observable_interface {
    virtual ~event_manager() final;

    [[nodiscard]] observing::endable observe(observing::caller<std::shared_ptr<event>>::handler_f &&) override;

    [[nodiscard]] static std::shared_ptr<event_manager> make_shared();

   private:
    std::shared_ptr<event> _cursor_event{nullptr};
    std::unordered_map<uintptr_t, std::shared_ptr<event>> _touch_events;
    std::unordered_map<uint16_t, std::shared_ptr<event>> _key_events;
    std::unordered_map<uint32_t, std::shared_ptr<event>> _modifier_events;

    observing::notifier_ptr<std::shared_ptr<event>> const _notifier =
        observing::notifier<std::shared_ptr<event>>::make_shared();

    event_manager();

    event_manager(event_manager const &) = delete;
    event_manager(event_manager &&) = delete;
    event_manager &operator=(event_manager const &) = delete;
    event_manager &operator=(event_manager &&) = delete;

    void input_cursor_event(cursor_event const &value) override;
    void input_touch_event(event_phase const, touch_event const &) override;
    void input_key_event(event_phase const, key_event const &) override;
    void input_modifier_event(modifier_flags const &, double const) override;
};
}  // namespace yas::ui