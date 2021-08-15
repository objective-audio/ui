//
//  yas_ui_metal_view_controller_dependency.h
//

#pragma once

namespace yas::ui {
struct renderer_for_view {
    virtual ~renderer_for_view() = default;

    virtual void view_render() = 0;
};
}  // namespace yas::ui
