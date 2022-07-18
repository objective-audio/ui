//
//  yas_ui_color.h
//

#pragma once

#include <ui/yas_ui_rgb_color.h>

namespace yas::ui {
struct color final {
    union {
        struct {
            float red;
            float green;
            float blue;
            float alpha;
        };
        ui::rgb_color rgb;
        simd::float4 v;
    };

    bool operator==(color const &rhs) const;
    bool operator!=(color const &rhs) const;
};

static_assert(sizeof(color) == (sizeof(float) * 4));
}  // namespace yas::ui

namespace yas {
ui::color to_color(ui::rgb_color const &, float const alpha = 1.0f);

std::string to_string(ui::color const &color);
}  // namespace yas

std::ostream &operator<<(std::ostream &, yas::ui::color const &);
