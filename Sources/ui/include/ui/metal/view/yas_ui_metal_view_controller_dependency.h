//
//  yas_ui_metal_view_controller_dependency.h
//

#pragma once

#include <ui/color/yas_ui_color.h>

#include <observing/umbrella.hpp>

namespace yas::ui {
struct renderer_for_view {
    virtual ~renderer_for_view() = default;

    virtual void view_render() = 0;
    [[nodiscard]] virtual observing::endable observe_background_color(std::function<void(ui::color const &)> &&) = 0;
};
}  // namespace yas::ui
