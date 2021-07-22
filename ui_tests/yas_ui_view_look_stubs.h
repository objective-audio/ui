//
//  yas_ui_view_look_stubs.h
//

#pragma once

#include <ui/yas_ui_umbrella.h>

namespace yas::ui {
struct view_look_scale_factor_stub final : view_look_scale_factor_interface {
    observing::value::holder_ptr<double> const scale_factor_holder;

    [[nodiscard]] virtual double scale_factor() const {
        return this->scale_factor_holder->value();
    }

    [[nodiscard]] virtual observing::syncable observe_scale_factor(observing::caller<double>::handler_f &&handler) {
        return this->scale_factor_holder->observe(std::move(handler));
    }

    static std::shared_ptr<view_look_scale_factor_stub> make_shared(double const scale_factor) {
        return std::shared_ptr<view_look_scale_factor_stub>(new view_look_scale_factor_stub{scale_factor});
    }

   private:
    view_look_scale_factor_stub(double const scale_factor)
        : scale_factor_holder(observing::value::holder<double>::make_shared(scale_factor)) {
    }
};
}  // namespace yas::ui
