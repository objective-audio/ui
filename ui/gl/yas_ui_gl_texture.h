//
//  yas_ui_gl_texture.h
//

#pragma once

#include <ui/yas_ui_types.h>

namespace yas::ui {
struct gl_texture_interface {
    virtual ~gl_texture_interface() = default;

    [[nodiscard]] virtual bool is_ready() const = 0;
    virtual void replace_data(uint_region const region, void const *data) = 0;
};
}  // namespace yas::ui
