//
//  yas_ui_common_dependency.h
//

#pragma once

#include <ui/yas_ui_types.h>

#include <observing/yas_observing_umbrella.hpp>

namespace yas::ui {
struct scale_factor_observable {
    virtual ~scale_factor_observable() = default;

    [[nodiscard]] virtual double scale_factor() const = 0;
    [[nodiscard]] virtual observing::syncable observe_scale_factor(std::function<void(double const &)> &&) = 0;
};

struct appearance_observable {
    virtual ~appearance_observable() = default;

    [[nodiscard]] virtual ui::appearance appearance() const = 0;
    [[nodiscard]] virtual observing::syncable observe_appearance(std::function<void(ui::appearance const &)> &&) = 0;
};

struct event_observable {
    virtual ~event_observable() = default;

    [[nodiscard]] virtual observing::endable observe(std::function<void(std::shared_ptr<event> const &)> &&) = 0;
};

struct collider_detectable {
    virtual ~collider_detectable() = default;

    [[nodiscard]] virtual bool detect(ui::point const &, std::shared_ptr<collider> const &) const = 0;
};

struct renderer_observable {
    virtual ~renderer_observable() = default;

    [[nodiscard]] virtual observing::endable observe_will_render(std::function<void(std::nullptr_t const &)> &&) = 0;
    [[nodiscard]] virtual observing::endable observe_did_render(std::function<void(std::nullptr_t const &)> &&) = 0;
};
}  // namespace yas::ui
