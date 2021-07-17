//
//  yas_ui_metal_view_controller_dependency.h
//

#pragma once

namespace yas::ui {
struct view_renderer_interface {
    virtual ~view_renderer_interface() = default;

    virtual void view_render() = 0;
};
}  // namespace yas::ui
