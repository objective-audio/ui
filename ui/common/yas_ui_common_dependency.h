//
//  yas_ui_common_dependency.h
//

#pragma once

#include <observing/yas_observing_umbrella.h>
#include <ui/yas_ui_types.h>

namespace yas::ui {
struct view_look_scale_factor_interface {
    virtual ~view_look_scale_factor_interface() = default;

    [[nodiscard]] virtual double scale_factor() const = 0;
    [[nodiscard]] virtual observing::syncable observe_scale_factor(observing::caller<double>::handler_f &&) = 0;
};

struct event_observable_interface {
    virtual ~event_observable_interface() = default;

    [[nodiscard]] virtual observing::endable observe(observing::caller<std::shared_ptr<event>>::handler_f &&) = 0;
};
}  // namespace yas::ui
