#pragma once

#include <ui/common/yas_ui_types.h>

namespace yas::ui {
struct translate_action_target {
    virtual void set_position(ui::point &&) = 0;
};

struct rotate_action_target {
    virtual void set_angle(ui::angle &&) = 0;
};

struct scale_action_target {
    virtual void set_scale(ui::size &&) = 0;
};

struct color_action_target {
    virtual void set_rgb_color(ui::rgb_color &&) = 0;
};

struct alpha_action_target {
    virtual void set_alpha(float &&) = 0;
};
}  // namespace yas::ui
