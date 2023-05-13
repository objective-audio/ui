//
//  yas_ui_multiple_touch.h
//

#pragma once

#include <cpp_utils/yas_system_time_provider.h>
#include <ui/yas_ui_touch_tracker_types.h>

#include <chrono>
#include <observing/yas_observing_umbrella.hpp>

namespace yas::ui {
struct multiple_touch final {
    [[nodiscard]] static std::shared_ptr<multiple_touch> make_shared(
        std::size_t const required_count = 2, double const max_interval = 0.3,
        std::shared_ptr<system_time_providable> const &provider = system_time_provider::make_shared());

    void handle_event(touch_tracker_phase const phase, uintptr_t const identifier);

    [[nodiscard]] observing::endable observe(std::function<void(uintptr_t const &)> &&);

   private:
    using time_point_t = std::chrono::time_point<std::chrono::system_clock>;
    using duration_t = std::chrono::duration<double>;

    std::size_t const _required_count;
    duration_t const _max_interval;
    std::shared_ptr<system_time_providable> const _system_time_provider;

    struct tapped final {
        time_point_t timepoint;
        std::size_t count;
        uintptr_t identifier;
    };

    std::optional<tapped> _tapped;

    observing::notifier_ptr<uintptr_t> const _notifier;

    multiple_touch(std::size_t const required_count, double const max_interval,
                   std::shared_ptr<system_time_providable> const &);

    bool _can_increment(uintptr_t const identifier, time_point_t const &timestamp);
};
}  // namespace yas::ui
