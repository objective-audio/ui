//
//  yas_ui_rgb_color.h
//

#pragma once

#include <simd/simd.h>

#include <ostream>
#include <string>

namespace yas::ui {
struct rgb_color {
    union {
        struct {
            float red;
            float green;
            float blue;
        };
        simd::float3 v;
    };

    bool operator==(rgb_color const &rhs) const;
    bool operator!=(rgb_color const &rhs) const;
    rgb_color operator*(rgb_color const &rhs) const;
    rgb_color operator*(float const &rhs) const;

    explicit operator bool() const;
};

[[nodiscard]] ui::rgb_color const &white_color();
[[nodiscard]] ui::rgb_color const &black_color();
[[nodiscard]] ui::rgb_color const &gray_color();
[[nodiscard]] ui::rgb_color const &dark_gray_color();
[[nodiscard]] ui::rgb_color const &light_gray_color();
[[nodiscard]] ui::rgb_color const &red_color();
[[nodiscard]] ui::rgb_color const &green_color();
[[nodiscard]] ui::rgb_color const &blue_color();
[[nodiscard]] ui::rgb_color const &cyan_color();
[[nodiscard]] ui::rgb_color const &yellow_color();
[[nodiscard]] ui::rgb_color const &magenta_color();
[[nodiscard]] ui::rgb_color const &orange_color();
[[nodiscard]] ui::rgb_color const &purple_color();
[[nodiscard]] ui::rgb_color const &brown_color();

ui::rgb_color hsb_color(float const hue, float const saturation, float const brightness);
ui::rgb_color hsl_color(float const hue, float const saturation, float const lightness);
}  // namespace yas::ui

namespace yas {
simd::float4 to_float4(ui::rgb_color const &, float alpha);

std::string to_string(ui::rgb_color const &);
}  // namespace yas

std::ostream &operator<<(std::ostream &, yas::ui::rgb_color const &);
